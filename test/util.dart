import 'package:aw_router/src/utils/util.dart' show normalizePath;
import 'package:test/test.dart';

void main() {
  group('normalizePath', () {
    test('adds leading slash if missing', () {
      expect(normalizePath('foo/bar'), '/foo/bar');
      expect(normalizePath('/foo/bar'), '/foo/bar');
    });

    test('removes trailing slash (except root)', () {
      expect(normalizePath('/foo/bar/'), '/foo/bar');
      expect(normalizePath('/foo/bar'), '/foo/bar');
      expect(normalizePath('/'), '/');
    });

    test('keeps trailing slash for <path| wildcard', () {
      expect(normalizePath('/foo/<path|[^]*>/'), '/foo/<path|[^]*>/');
      expect(normalizePath('/foo/<path|[^]*/>'), '/foo/<path|[^]*/>');
      expect(normalizePath('/foo/<path|[^]*>'), '/foo/<path|[^]*>');
    });

    test('does not remove trailing slash if path is root', () {
      expect(normalizePath('/'), '/');
    });

    test('removes double slashes except root', () {
      expect(normalizePath('//foo//bar//'), '/foo/bar');
      expect(normalizePath('foo//bar'), '/foo/bar');
      expect(normalizePath('////'), '/');
    });

    test('handles empty string', () {
      expect(normalizePath(''), '/');
    });

    test('preserves regex/wildcard markers', () {
      expect(normalizePath('/foo/<path|[^]*/>'), '/foo/<path|[^]*/>');
      expect(normalizePath('/foo/<.*>'), '/foo/<.*>');
    });

    test('does not break on already normalized paths', () {
      expect(normalizePath('/foo/bar'), '/foo/bar');
      expect(normalizePath('/foo/bar/baz'), '/foo/bar/baz');
    });
  });
}
