import 'package:flutter_test/flutter_test.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';

// StringExtensions is pure logic with no Flutter dependency, and it carries real
// weight: `iconSvg` is what resolves every bottom-nav icon, so a change to that
// path scheme silently blanks the nav bar. Everything here is a pure function of
// its input — no clock, no I/O.
void main() {
  group('Given an asset name', () {
    group('When it is resolved to an asset path', () {
      test('Then iconSvg points into the icons directory', () {
        // The bottom nav derives its asset from the tab label via this getter.
        expect('bible'.iconSvg, 'assets/images/icons/bible.svg');
        expect('bible_fill'.iconSvg, 'assets/images/icons/bible_fill.svg');
      });

      test('Then the other asset helpers use their own directories', () {
        expect('logo'.png, 'assets/images/logo.png');
        expect('scene'.webp, 'assets/images/scene.webp');
        expect('hymns'.json, 'assets/json/hymns.json');
        expect('intro'.onboarding, 'assets/images/onboarding/intro.webp');
        expect('spinner'.lottie, 'assets/images/lottie/spinner.json');
      });
    });
  });

  group('Given text to re-case', () {
    group('When capitalize is applied', () {
      test('Then the first letter is raised and the rest lowered', () {
        expect('hello'.capitalize, 'Hello');
        // Note it lowercases the remainder rather than leaving it alone.
        expect('hELLO'.capitalize, 'Hello');
      });

      test('Then an empty string is returned untouched', () {
        expect(''.capitalize, '');
      });
    });

    group('When capitalizeWords is applied', () {
      test('Then every word is capitalized', () {
        expect('amazing grace'.capitalizeWords, 'Amazing Grace');
      });

      test('Then repeated spaces do not throw', () {
        expect('a  b'.capitalizeWords, 'A  B');
      });
    });

    group('When converting between camelCase and snake_case', () {
      test('Then snake_case becomes camelCase', () {
        expect('user_name'.toCamelCase, 'userName');
      });

      test('Then a single word is left alone', () {
        expect('user'.toCamelCase, 'user');
      });

      test('Then camelCase becomes snake_case without a leading underscore', () {
        expect('userName'.toSnakeCase, 'user_name');
        expect('UserName'.toSnakeCase, 'user_name');
      });
    });
  });

  group('Given text containing markup or loose whitespace', () {
    group('When it is cleaned', () {
      test('Then stripHtml removes the tags but keeps the text', () {
        expect('<p>Hello</p>'.stripHtml, 'Hello');
      });

      test('Then stripHtmlAndWhitespace also collapses runs of whitespace', () {
        expect('<p>Hello  \n  World</p>'.stripHtmlAndWhitespace, 'Hello World');
      });

      test('Then removeExtraSpaces collapses and trims', () {
        expect('  Hello    World  '.removeExtraSpaces, 'Hello World');
      });
    });
  });

  group('Given a string to validate', () {
    group('When checked as an email', () {
      test('Then well-formed addresses pass and malformed ones fail', () {
        expect('test@example.com'.isValidEmail, isTrue);
        expect('test@example'.isValidEmail, isFalse);
        expect('not-an-email'.isValidEmail, isFalse);
      });
    });

    group('When checked as a URL', () {
      test('Then only http(s) URLs pass', () {
        expect('https://example.com'.isValidUrl, isTrue);
        expect('ftp://example.com'.isValidUrl, isFalse);
      });
    });

    group('When checked for character class', () {
      test('Then isNumeric, isAlpha and isAlphanumeric discriminate', () {
        expect('123'.isNumeric, isTrue);
        expect('12a'.isNumeric, isFalse);

        expect('abc'.isAlpha, isTrue);
        expect('abc1'.isAlpha, isFalse);

        expect('abc123'.isAlphanumeric, isTrue);
        expect('abc 123'.isAlphanumeric, isFalse);
      });

      test('Then an empty string satisfies none of them', () {
        expect(''.isNumeric, isFalse);
        expect(''.isAlpha, isFalse);
        expect(''.isAlphanumeric, isFalse);
      });
    });
  });

  group('Given a string to format or parse', () {
    group('When formatted with commas', () {
      test('Then thousands separators are inserted', () {
        expect('1000000'.withCommas, '1,000,000');
      });

      test('Then unparseable input degrades to zero rather than throwing', () {
        expect('abc'.withCommas, '0');
      });
    });

    group('When truncated', () {
      test('Then a short string is returned unchanged', () {
        expect('Hello'.truncate(8), 'Hello');
      });

      test('Then a long string is cut at maxLength and the ellipsis appended',
          () {
        // Worth pinning: the doc comment claims 'Hello World'.truncate(8) gives
        // 'Hello...', but the implementation appends the ellipsis AFTER the cut,
        // so the result runs past maxLength. This asserts the real behaviour.
        expect('Hello World'.truncate(8), 'Hello Wo...');
      });

      test('Then the ellipsis is overridable', () {
        expect('Hello World'.truncate(5, ellipsis: '…'), 'Hello…');
      });
    });

    group('When parsed to a number', () {
      test('Then valid input parses and invalid input is null', () {
        expect('42'.toIntOrNull, 42);
        expect('4.5'.toIntOrNull, isNull);
        expect('4.5'.toDoubleOrNull, 4.5);
        expect('abc'.toDoubleOrNull, isNull);
      });
    });
  });
}
