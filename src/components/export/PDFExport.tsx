"use client";

import type { BusinessCase } from "@/lib/export/types";
import { preparePDFContent } from "@/lib/export/pdf";

type PDFExportProps = {
  data?: BusinessCase;
};

// Simple viewer stub that prepares PDF content; actual rendering/printing can be added later.
export default function PDFExport({ data }: PDFExportProps) {
  const prepared = data ? preparePDFContent(data) : null;

  return (
    <div className="rounded-lg border p-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold">PDF Export</h2>
        <span className="text-xs text-muted-foreground">Preview</span>
      </div>

      {!prepared ? (
        <p className="mt-2 text-sm text-muted-foreground">
          Provide business case data to generate a PDF export.
        </p>
      ) : (
        <div className="mt-3 space-y-2 text-sm">
          <div className="font-medium">{prepared.title}</div>
          <div className="rounded-md border bg-muted p-3 text-xs">
            <div className="mb-2 font-semibold">Sections</div>
            <ul className="list-disc space-y-1 pl-4">
              {prepared.sections.map((section) => (
                <li key={section.heading}>
                  {section.heading} ({section.type})
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </div>
  );
}
