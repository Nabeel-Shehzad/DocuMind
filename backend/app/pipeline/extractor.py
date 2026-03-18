"""
Extractor Pipeline Stage
PDF/Image → raw text + metadata
"""

import fitz  # PyMuPDF
import pdfplumber
import pytesseract
from PIL import Image
from pathlib import Path
from typing import Optional
import io
import logging

logger = logging.getLogger(__name__)


class DocumentExtractor:
    """
    Stage 1 of the ingestion pipeline.
    Accepts PDF or image files and returns:
      - pages: list of {"page": int, "text": str, "tables": list}
      - metadata: {"page_count": int, "file_type": str}
    """

    SUPPORTED_IMAGES = {".png", ".jpg", ".jpeg", ".tiff", ".bmp", ".webp"}
    SUPPORTED_DOCS   = {".pdf"}

    def extract(self, file_path: str) -> dict:
        path = Path(file_path)
        suffix = path.suffix.lower()

        if suffix == ".pdf":
            return self._extract_pdf(file_path)
        elif suffix in self.SUPPORTED_IMAGES:
            return self._extract_image(file_path)
        else:
            raise ValueError(f"Unsupported file type: {suffix}")

    # ── PDF extraction ───────────────────────────────────────────────────────

    def _extract_pdf(self, file_path: str) -> dict:
        pages = []

        # Pass 1: pdfplumber — best for tables
        tables_by_page: dict[int, list] = {}
        try:
            with pdfplumber.open(file_path) as pdf:
                for i, page in enumerate(pdf.pages):
                    tables = page.extract_tables()
                    if tables:
                        tables_by_page[i] = tables
        except Exception as e:
            logger.warning(f"pdfplumber table extraction failed: {e}")

        # Pass 2: PyMuPDF — best for text + OCR fallback on scanned pages
        doc = fitz.open(file_path)
        for page_num in range(len(doc)):
            page = doc[page_num]
            text = page.get_text("text").strip()

            # If page has no selectable text → OCR via image render
            if not text:
                logger.info(f"Page {page_num + 1} appears scanned — running OCR")
                text = self._ocr_page(page)

            pages.append({
                "page":   page_num + 1,
                "text":   text,
                "tables": tables_by_page.get(page_num, []),
            })
        doc.close()

        return {
            "pages":    pages,
            "metadata": {
                "page_count": len(pages),
                "file_type":  "pdf",
            },
        }

    # ── Image extraction (OCR) ───────────────────────────────────────────────

    def _extract_image(self, file_path: str) -> dict:
        image = Image.open(file_path)
        text  = pytesseract.image_to_string(image)

        return {
            "pages": [{"page": 1, "text": text.strip(), "tables": []}],
            "metadata": {
                "page_count": 1,
                "file_type":  Path(file_path).suffix.lower().lstrip("."),
            },
        }

    # ── OCR helper ───────────────────────────────────────────────────────────

    def _ocr_page(self, page: fitz.Page) -> str:
        """Render a PDF page to image and OCR it."""
        try:
            mat = fitz.Matrix(2, 2)           # 2× zoom for better OCR quality
            pix = page.get_pixmap(matrix=mat)
            img = Image.open(io.BytesIO(pix.tobytes("png")))
            return pytesseract.image_to_string(img).strip()
        except Exception as e:
            logger.error(f"OCR failed: {e}")
            return ""
