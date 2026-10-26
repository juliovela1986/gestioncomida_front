import 'package:flutter_test/flutter_test.dart';
import 'package:gestioncomida_front/core/ticket_discount_utils.dart';

void main() {
  const pdfTicketRawText = '''
              ***CARREFOUR***
   **************************************
            BAÑADOR HUGGIES 20 P89 2R15 12,65
            APOSITOS SALVELOX CE86
            2 x ( 2,79 ) 5,58
            DESCUENTO EN 2ª UNIDAD CE86 -1,40
            LECHE NAN SUPREME 2 27,20
            ==========================================
              SUBTOTAL                          44,03
            ==========================================
            DTO. VALE QV020626_50V 2Q           -22,08
            9980015071251 / 88980552862000002751
            DTO. VALE  15% ACCESS OFIT          -4,49
            4 ART. TOTAL A PAGAR                17,46
''';

  test('detecta marcadores de descuento Carrefour', () {
    expect(hasDiscountMarkers(pdfTicketRawText), isTrue);
    expect(hasDiscountMarkers('ticket sin descuentos'), isFalse);
  });

  test('no confunde codigos de vale con importes', () {
    expect(extractCarrefourGlobalVoucherDiscount(pdfTicketRawText), closeTo(26.57, 0.01));
  });

  test('extrae total pagado Carrefour', () {
    expect(extractCarrefourPaidTotal(pdfTicketRawText), closeTo(17.46, 0.01));
  });

  test('calcula descuento global y total de visualización', () {
    const subtotal = 44.03;
    final discount = calculateGlobalDiscount(
      rawText: pdfTicketRawText,
      subtotal: subtotal,
      backendTicketTotal: '17.46',
      supermarketName: 'CARREFOUR',
    );
    expect(discount, closeTo(26.57, 0.01));

    final total = calculateTicketDisplayTotal(
      subtotal: subtotal,
      rawText: pdfTicketRawText,
      backendTicketTotal: '17.46',
      supermarketName: 'CARREFOUR',
    );
    expect(total, closeTo(17.46, 0.01));
  });

  test('no interpreta 15% ni codigos QV como importe de cupón', () {
    const truncatedText = '''
SUBTOTAL                          44,03
DTO. VALE QV020626_50V 2Q           -22,08
9980015071251 / 88980552862000002751
DTO. VALE  15% ACCESS OFIT
''';
    expect(extractCarrefourGlobalVoucherDiscount(truncatedText), closeTo(22.08, 0.01));
    expect(
      calculateGlobalDiscount(
        rawText: truncatedText,
        subtotal: 44.03,
        supermarketName: 'CARREFOUR',
      ),
      closeTo(22.08, 0.01),
    );
    expect(
      calculateTicketDisplayTotal(
        subtotal: 44.03,
        rawText: truncatedText,
        supermarketName: 'CARREFOUR',
      ),
      closeTo(21.95, 0.01),
    );
  });
}
