// Global configuration dictionary
#let config = (
  // Year for the planner
  year: 2025,
  
  // Page layout
  // reMarkable 2 dimensions: width: 158mm, height: 210mm
  // A4 dimensions would be: width: 210mm, height: 297mm
  // US Letter: width: 215.9mm, height: 279.4mm
  page_width: 158mm,
  page_height: 210mm,
  margin_x: 5mm,
  margin_y: 5mm,
  
  // Header height (date + day name + spacing)
  header_height: 15mm,
  
  // Font sizes
  font_size_large: 24pt,
  font_size_medium: 12pt,
  font_size_small: 11pt,
  
  // Line spacing for daily planner
  // Total vertical space between lines (including checkbox and spacing)
  line_height: 7mm,
  
  // Checkbox size in mm
  // Should be smaller than line_height to allow proper spacing
  // Common combinations: (line_height: 6mm, checkbox_size: 3.5mm), 
  //                     (line_height: 7mm, checkbox_size: 4mm),
  //                     (line_height: 8mm, checkbox_size: 5mm)
  checkbox_size: 4mm,
  
  // Checkbox line darkness (0-255, where 0 is black, 255 is very light)
  // Common values: 0 (black), 100 (dark gray), 150 (medium gray), 200 (light gray)
  checkbox_line_color: 200,
  
  // Number of lines for each section in daily planner
  priority_lines: 4,    // Top Priority section (no checkboxes)
  primary_lines: 13,    // Primary section (with checkboxes)
  secondary_lines: 7,   // Secondary section (with checkboxes)
  
  // Grid size for daily notes pages
  // Common values: 4mm (fine), 5mm (standard), 6mm (large), 8mm (extra large)
  notes_grid_size: 5mm,
  
  // Labels for navigation
  calendar_label: "calendar-view",
)