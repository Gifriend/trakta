import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../../features/attendance/data/repositories/attendance_repository.dart';
import '../models/attendance.dart';
import '../utils/strings.dart';
import '../utils/wib.dart';

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(ref.watch(attendanceRepositoryProvider)),
);

class ExportService {
  const ExportService(this._repository);
  final AttendanceRepository _repository;
  Future<Uint8List> create(
    String uid,
    AttendanceRange range,
    AppStrings strings, {
    bool includePhotos = false,
  }) async {
    final days = await _repository.all(uid, range);
    final photos = <String, Uint8List>{};
    if (includePhotos) {
      // Sequential reads bound memory and avoid flooding Firestore for long ranges.
      for (final day in days) {
        for (final kind in AttendanceKind.values) {
          if (kind == AttendanceKind.checkOut && day.checkOut == null) continue;
          final photo = await _repository.photo(uid, day.dateKey, kind);
          if (photo != null) photos['${day.dateKey}/${kind.name}'] = photo;
        }
      }
    }
    return AttendanceWorkbook.encode(
      days,
      strings,
      includePhotos: includePhotos,
      photos: photos,
    );
  }
}

/// Small OOXML writer: typed strings prevent formula injection; photos are
/// embedded in the package so the exported workbook has no external data links.
abstract final class AttendanceWorkbook {
  static const _spreadsheet =
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const _relationship =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  static const _package =
      'http://schemas.openxmlformats.org/package/2006/relationships';
  static String _xml(String text) => text
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
  static Uint8List encode(
    List<AttendanceDay> days,
    AppStrings strings, {
    bool includePhotos = false,
    Map<String, Uint8List> photos = const {},
  }) {
    final archive = Archive();
    void file(String path, String xml) => archive.addFile(
      ArchiveFile.string(
        path,
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>$xml',
      ),
    );
    final headers = [
      'Tanggal',
      if (includePhotos) ...['Foto masuk', 'Foto pulang'],
      'Masuk (WIB)',
      'Pulang (WIB)',
      'Durasi',
      'Status',
      'Lokasi kerja masuk',
      'Lokasi kerja pulang',
      'Catatan masuk',
      'Catatan pulang',
    ];
    String textCell(int column, int row, String text, [int style = 0]) =>
        '<c r="${String.fromCharCode(65 + column)}$row" s="$style" t="inlineStr"><is><t xml:space="preserve">${_xml(text)}</t></is></c>';
    String numberCell(int column, int row, num? value, int style) =>
        value == null
        ? ''
        : '<c r="${String.fromCharCode(65 + column)}$row" s="$style"><v>$value</v></c>';
    double time(DateTime value) {
      final local = Wib.at(value);
      return (local.hour * 3600 + local.minute * 60 + local.second) / 86400;
    }

    final rows = StringBuffer('<row r="1" ht="26" customHeight="1">');
    for (var i = 0; i < headers.length; i++) {
      rows.write(textCell(i, 1, strings.t(headers[i]), 1));
    }
    rows.write('</row>');
    final anchors = StringBuffer(), imageRels = StringBuffer();
    var imageCount = 0;
    for (var i = 0; i < days.length; i++) {
      final day = days[i], row = i + 2;
      final start = day.checkIn.timestamp, end = day.checkOut?.timestamp;
      rows.write(
        '<row r="$row" ht="${includePhotos ? 126 : 32}" customHeight="1">',
      );
      rows.write(
        numberCell(
          0,
          row,
          Wib.fromKey(
            day.dateKey,
          ).difference(DateTime.utc(1899, 12, 30)).inDays,
          2,
        ),
      );
      var column = 1;
      if (includePhotos) {
        for (final kind in AttendanceKind.values) {
          final photo = photos['${day.dateKey}/${kind.name}'];
          if (photo != null) {
            imageCount++;
            archive.addFile(
              ArchiveFile('xl/media/image$imageCount.jpg', photo.length, photo),
            );
            imageRels.write(
              '<Relationship Id="rId$imageCount" Type="$_relationship/image" Target="../media/image$imageCount.jpg"/>',
            );
            final decoded = img.decodeJpg(photo);
            final ratio = decoded == null
                ? 1.4
                : decoded.width / decoded.height;
            final width = ratio > 216 / 154 ? 216.0 : 154.0 * ratio;
            final height = width / ratio;
            anchors.write(
              '<xdr:oneCellAnchor><xdr:from><xdr:col>$column</xdr:col><xdr:colOff>57150</xdr:colOff><xdr:row>${row - 1}</xdr:row><xdr:rowOff>57150</xdr:rowOff></xdr:from><xdr:ext cx="${(width * 9525).round()}" cy="${(height * 9525).round()}"/><xdr:pic><xdr:nvPicPr><xdr:cNvPr id="$imageCount" name="Photo $imageCount"/><xdr:cNvPicPr><a:picLocks noChangeAspect="1"/></xdr:cNvPicPr></xdr:nvPicPr><xdr:blipFill><a:blip r:embed="rId$imageCount"/><a:stretch><a:fillRect/></a:stretch></xdr:blipFill><xdr:spPr><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></xdr:spPr></xdr:pic><xdr:clientData/></xdr:oneCellAnchor>',
            );
          } else if (kind == AttendanceKind.checkIn || day.checkOut != null) {
            rows.write(
              textCell(column, row, strings.t('Foto tidak ditemukan.')),
            );
          }
          column++;
        }
      }
      rows.write(numberCell(column++, row, time(start), 3));
      rows.write(numberCell(column++, row, end == null ? null : time(end), 3));
      rows.write(
        numberCell(
          column++,
          row,
          end == null
              ? null
              : end.difference(start).inSeconds.clamp(0, 999999999) / 86400,
          4,
        ),
      );
      for (final value in [
        strings.t(end == null ? 'Sudah masuk' : 'Lengkap'),
        strings.t(day.checkIn.mode.label),
        day.checkOut == null ? '' : strings.t(day.checkOut!.mode.label),
        day.checkIn.note,
        day.checkOut?.note ?? '',
      ]) {
        rows.write(textCell(column++, row, value));
      }
      rows.write('</row>');
    }
    file(
      '[Content_Types].xml',
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="jpg" ContentType="image/jpeg"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>${imageCount > 0 ? '<Override PartName="/xl/drawings/drawing1.xml" ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>' : ''}</Types>',
    );
    file(
      '_rels/.rels',
      '<Relationships xmlns="$_package"><Relationship Id="rId1" Type="$_relationship/officeDocument" Target="xl/workbook.xml"/></Relationships>',
    );
    file(
      'xl/workbook.xml',
      '<workbook xmlns="$_spreadsheet" xmlns:r="$_relationship"><sheets><sheet name="${_xml(strings.t('Riwayat presensi'))}" sheetId="1" r:id="rId1"/></sheets></workbook>',
    );
    file(
      'xl/_rels/workbook.xml.rels',
      '<Relationships xmlns="$_package"><Relationship Id="rId1" Type="$_relationship/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="$_relationship/styles" Target="styles.xml"/></Relationships>',
    );
    file(
      'xl/styles.xml',
      '<styleSheet xmlns="$_spreadsheet"><numFmts count="3"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/><numFmt numFmtId="165" formatCode="hh:mm:ss"/><numFmt numFmtId="166" formatCode="[h]:mm:ss"/></numFmts><fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font></fonts><fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF124E43"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="5"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf><xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/><xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/><xf numFmtId="166" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>',
    );
    final columns = List.generate(
      headers.length,
      (i) =>
          '<col min="${i + 1}" max="${i + 1}" width="${includePhotos && i >= 1 && i <= 2
              ? 34
              : i >= headers.length - 2
              ? 42
              : 22}" customWidth="1"/>',
    ).join();
    file(
      'xl/worksheets/sheet1.xml',
      '<worksheet xmlns="$_spreadsheet" xmlns:r="$_relationship"><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><cols>$columns</cols><sheetData>$rows</sheetData><autoFilter ref="A1:${String.fromCharCode(64 + headers.length)}${days.length + 1}"/>${imageCount > 0 ? '<drawing r:id="rId1"/>' : ''}</worksheet>',
    );
    if (imageCount > 0) {
      file(
        'xl/worksheets/_rels/sheet1.xml.rels',
        '<Relationships xmlns="$_package"><Relationship Id="rId1" Type="$_relationship/drawing" Target="../drawings/drawing1.xml"/></Relationships>',
      );
      file(
        'xl/drawings/drawing1.xml',
        '<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="$_relationship">$anchors</xdr:wsDr>',
      );
      file(
        'xl/drawings/_rels/drawing1.xml.rels',
        '<Relationships xmlns="$_package">$imageRels</Relationships>',
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}
