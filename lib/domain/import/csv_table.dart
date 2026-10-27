/// 引号感知的 CSV 行解析（domain 层共享，无第三方依赖）。
///
/// 供账单解析器与导入服务复用；处理引号包裹、引号转义（""）、
/// 逗号/制表符分隔、\r\n 与 BOM。
class CsvTable {
  CsvTable(this.rows);

  final List<List<String>> rows;

  static CsvTable parse(String text) {
    final cleaned = text.startsWith('\uFEFF') ? text.substring(1) : text;
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    for (var i = 0; i < cleaned.length; i++) {
      final ch = cleaned[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < cleaned.length && cleaned[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',' || ch == '\t') {
          row.add(field.toString().trim());
          field = StringBuffer();
        } else if (ch == '\n' || ch == '\r') {
          if (field.isNotEmpty || row.isNotEmpty) {
            row.add(field.toString().trim());
            rows.add(row);
            row = <String>[];
            field = StringBuffer();
          }
          if (ch == '\r' && i + 1 < cleaned.length && cleaned[i + 1] == '\n') {
            i++;
          }
        } else {
          field.write(ch);
        }
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString().trim());
      rows.add(row);
    }
    return CsvTable(rows);
  }

  /// 首个包含全部 [names]（规范化比较）的行下标；未找到返回 -1。
  int headerRowIndex(Set<String> names) {
    for (var i = 0; i < rows.length; i++) {
      final normalized =
          rows[i].map(normalizeHeaderCell).toSet();
      if (normalized.containsAll(names)) return i;
    }
    return -1;
  }

  /// 规范化表头单元格：去空白、全角括号→半角、转小写。
  static String normalizeHeaderCell(String s) => s
      .replaceAll('（', '(')
      .replaceAll('）', ')')
      .replaceAll(RegExp(r'\s+'), '')
      .toLowerCase();

  /// 按规范化名取列下标（相对 [headerRow]）；缺列返回 -1。
  int columnIndex(int headerRow, String name) {
    final target = normalizeHeaderCell(name);
    final cells = rows[headerRow];
    for (var i = 0; i < cells.length; i++) {
      if (normalizeHeaderCell(cells[i]) == target) return i;
    }
    return -1;
  }
}
