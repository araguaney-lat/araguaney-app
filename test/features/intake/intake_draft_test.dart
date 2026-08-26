import 'package:araguaney_app/core/api/generated/models/donor_input.dart';
import 'package:araguaney_app/features/intake/domain/box_draft_input.dart';
import 'package:araguaney_app/features/intake/domain/intake_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

BoxDraftInput boxInput({
  String productTypeId = 'pt-1',
  int quantity = 10,
  String unit = 'unidad',
  String? batch,
  DateTime? expiryDate,
}) => BoxDraftInput(
  productType: productTypeRow(id: productTypeId),
  quantity: quantity,
  unit: unit,
  batch: batch,
  expiryDate: expiryDate,
);

void main() {
  const draft = IntakeDraft(captureId: 'capture-1');

  group('the idempotency key', () {
    test('survives every edit the form can make', () {
      final edited = draft
          .copyWith(campaignId: 'campaign-1')
          .addBox(boxInput())
          .copyWith(notes: 'entregado en la tarde')
          .removeBox(0)
          .withoutDonor();

      expect(edited.captureId, 'capture-1');
    });

    test('travels in the request', () {
      expect(draft.addBox(boxInput()).toRequest().captureId, 'capture-1');
    });
  });

  group('boxes', () {
    test('a capture without boxes cannot be submitted', () {
      expect(draft.isSubmittable, isFalse);
      expect(draft.addBox(boxInput()).isSubmittable, isTrue);
    });

    test('editing a box leaves the others alone', () {
      final withTwo = draft
          .addBox(boxInput(productTypeId: 'pt-1'))
          .addBox(boxInput(productTypeId: 'pt-2'));

      final edited = withTwo.replaceBox(0, boxInput(quantity: 99));

      expect(edited.boxes.first.quantity, 99);
      expect(edited.boxes.last.productType.id, 'pt-2');
    });

    test('removing a box does not mutate the previous capture', () {
      final withTwo = draft.addBox(boxInput()).addBox(boxInput());

      final removed = withTwo.removeBox(0);

      expect(withTwo.boxes, hasLength(2));
      expect(removed.boxes, hasLength(1));
    });

    test('each box carries one product, one batch and one expiry', () {
      // The invariant is not imposed by this class: it is the shape of
      // `BoxDraft` in the contract, and that is why there is nowhere to write a
      // second product.
      final expiry = DateTime.utc(2027, 1, 31);
      final request = draft
          .addBox(boxInput(batch: 'L-42', expiryDate: expiry))
          .toRequest();

      final box = request.boxes.single;
      expect(box.productTypeId, 'pt-1');
      expect(box.batch, 'L-42');
      expect(box.expiryDate, expiry);
    });
  });

  group('the donor', () {
    const donor = DonorInput(
      firstName: 'Ana',
      lastName: 'Pérez',
      donorType: DonorType.legal,
    );

    test('clearing it also drops the accepted terms', () {
      final identified = draft.copyWith(donor: donor, donorTermsAccepted: true);

      final anonymous = identified.withoutDonor();

      expect(anonymous.donor, isNull);
      expect(anonymous.donorTermsAccepted, isFalse);
    });

    test('clearing it keeps everything else', () {
      final identified = draft
          .copyWith(donor: donor, campaignId: 'campaign-1', notes: 'nota')
          .addBox(boxInput());

      final anonymous = identified.withoutDonor();

      expect(anonymous.campaignId, 'campaign-1');
      expect(anonymous.notes, 'nota');
      expect(anonymous.boxes, hasLength(1));
    });
  });

  group('the request sent to the server', () {
    test('blank free text is sent as absent, not as an empty string', () {
      final request = draft
          .copyWith(
            donanteLibre: '   ',
            notes: '',
            anonymousExceptionReason: '',
          )
          .addBox(boxInput())
          .toRequest();

      expect(request.donanteLibre, isNull);
      expect(request.notes, isNull);
      expect(request.anonymousExceptionReason, isNull);
    });

    test('free text is trimmed', () {
      final request = draft
          .copyWith(donanteLibre: '  Vecinos del barrio  ')
          .addBox(boxInput())
          .toRequest();

      expect(request.donanteLibre, 'Vecinos del barrio');
    });

    test('a donation scanned beforehand travels as its identifier', () {
      final request = draft
          .copyWith(donationId: 'donation-9')
          .addBox(boxInput())
          .toRequest();

      expect(request.donationId, 'donation-9');
    });
  });
}
