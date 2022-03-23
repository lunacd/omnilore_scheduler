void main() {
  // test('Generate gene: no chunks', () async {
  //   var splitControl = SplitControl([], [
  //     'Marion Smith',
  //     'Donald Tlougan',
  //     'Kathleen Fitzgerald',
  //     'Jim Parkman',
  //     'Janet Brown',
  //     'Sally Downie',
  //     'Sandra Pickar',
  //     'Lynn Solomita',
  //     'Ken Pickar',
  //     'Jim North',
  //     'Maria Ruiz',
  //     'Judy Close',
  //     'Gloria Dumais',
  //     'Ralph Brown',
  //     'Ken Meyer',
  //     'Elizabeth Brown',
  //     'Judy North',
  //     'Norman Stockwell',
  //     'Marilyn Landau',
  //     'Allan Conrad',
  //     'Helen Stockwell'
  //   ], 5, 9);
  //   for (var i = 0; i < 50; i++) {
  //     var result = splitControl.generateRandomGene();
  //     expect(result.sequence.length, 21);
  //     expect(result.sequence.where((section) => section == 0).length,
  //         result.sectionSizes[0]);
  //     expect(result.sequence.where((section) => section == 1).length,
  //         result.sectionSizes[1]);
  //     expect(result.sequence.where((section) => section == 2).length,
  //         result.sectionSizes[2]);
  //     expect(result.sectionSizes[0],
  //         allOf([greaterThanOrEqualTo(5), lessThanOrEqualTo(9)]));
  //     expect(result.sectionSizes[1],
  //         allOf([greaterThanOrEqualTo(5), lessThanOrEqualTo(9)]));
  //     expect(result.sectionSizes[2],
  //         allOf([greaterThanOrEqualTo(5), lessThanOrEqualTo(9)]));
  //   }
  // });
  //
  // test('Generate gene: chunks', () async {
  //   var splitControl = SplitControl([
  //     {'Marion Smith', 'Donald Tlougan'},
  //     {
  //       'Janet Brown',
  //       'Sally Downie',
  //       'Sandra Pickar',
  //       'Lynn Solomita',
  //     }
  //   ], [
  //     'Marion Smith',
  //     'Donald Tlougan',
  //     'Kathleen Fitzgerald',
  //     'Jim Parkman',
  //     'Janet Brown',
  //     'Sally Downie',
  //     'Sandra Pickar',
  //     'Lynn Solomita',
  //     'Ken Pickar',
  //     'Jim North',
  //     'Maria Ruiz',
  //     'Judy Close',
  //     'Gloria Dumais',
  //     'Ralph Brown',
  //     'Ken Meyer',
  //     'Elizabeth Brown',
  //     'Judy North',
  //     'Norman Stockwell',
  //     'Marilyn Landau',
  //     'Allan Conrad',
  //     'Helen Stockwell'
  //   ], 5, 9);
  //   var range = List<int>.generate(17, (index) => index);
  //   for (var i = 0; i < 50; i++) {
  //     var result = splitControl.generateRandomGene();
  //     expect(result.sequence.length, 17);
  //     expect(
  //         range.fold(0, (prev, index) {
  //           if (prev is int) {
  //             if (result.sequence[index] == 0) {
  //               return prev + splitControl.getChunk(index).length;
  //             } else {
  //               return prev;
  //             }
  //           }
  //           return prev;
  //         }),
  //         result.sectionSizes[0]);
  //     expect(
  //         range.fold(0, (prev, index) {
  //           if (prev is int) {
  //             if (result.sequence[index] == 1) {
  //               return prev + splitControl.getChunk(index).length;
  //             } else {
  //               return prev;
  //             }
  //           }
  //           return prev;
  //         }),
  //         result.sectionSizes[1]);
  //     expect(
  //         range.fold(0, (prev, index) {
  //           if (prev is int) {
  //             if (result.sequence[index] == 2) {
  //               return prev + splitControl.getChunk(index).length;
  //             } else {
  //               return prev;
  //             }
  //           }
  //           return prev;
  //         }),
  //         result.sectionSizes[2]);
  //     expect(result.sectionSizes[0],
  //         allOf([greaterThanOrEqualTo(5), lessThanOrEqualTo(9)]));
  //     expect(result.sectionSizes[1],
  //         allOf([greaterThanOrEqualTo(5), lessThanOrEqualTo(9)]));
  //     expect(result.sectionSizes[2],
  //         allOf([greaterThanOrEqualTo(5), lessThanOrEqualTo(9)]));
  //   }
  // });
  //
  // test('Generate gene: impossible split', () async {
  //   var splitControl = SplitControl([
  //     {
  //       'Sandra Pickar',
  //       'Lynn Solomita',
  //       'Marion Smith',
  //       'Donald Tlougan',
  //       'Ken Meyer',
  //       'Elizabeth Brown',
  //       'Judy North',
  //       'Norman Stockwell',
  //       'Marilyn Landau'
  //       // 'Allan Conrad'
  //     }
  //   ], [
  //     'Marion Smith',
  //     'Donald Tlougan',
  //     'Kathleen Fitzgerald',
  //     'Jim Parkman',
  //     'Janet Brown',
  //     'Sally Downie',
  //     'Sandra Pickar',
  //     'Lynn Solomita',
  //     'Ken Pickar',
  //     'Jim North',
  //     'Maria Ruiz',
  //     'Judy Close',
  //     'Gloria Dumais',
  //     'Ralph Brown',
  //     'Ken Meyer',
  //     'Elizabeth Brown',
  //     'Judy North',
  //     'Norman Stockwell',
  //     'Marilyn Landau',
  //     'Allan Conrad',
  //     'Helen Stockwell'
  //   ], 5, 9);
  //   expect(() => splitControl.generateRandomGene(),
  //       isNot(throwsA(isA<ImpossibleSplitException>())));
  //   splitControl = SplitControl([
  //     {
  //       'Sandra Pickar',
  //       'Lynn Solomita',
  //       'Marion Smith',
  //       'Donald Tlougan',
  //       'Ken Meyer',
  //       'Elizabeth Brown',
  //       'Judy North',
  //       'Norman Stockwell',
  //       'Marilyn Landau'
  //           'Allan Conrad'
  //     }
  //   ], [
  //     'Marion Smith',
  //     'Donald Tlougan',
  //     'Kathleen Fitzgerald',
  //     'Jim Parkman',
  //     'Janet Brown',
  //     'Sally Downie',
  //     'Sandra Pickar',
  //     'Lynn Solomita',
  //     'Ken Pickar',
  //     'Jim North',
  //     'Maria Ruiz',
  //     'Judy Close',
  //     'Gloria Dumais',
  //     'Ralph Brown',
  //     'Ken Meyer',
  //     'Elizabeth Brown',
  //     'Judy North',
  //     'Norman Stockwell',
  //     'Marilyn Landau',
  //     'Allan Conrad',
  //     'Helen Stockwell'
  //   ], 5, 9);
  //   expect(
  //       () => splitControl.generateRandomGene(),
  //       throwsA(allOf([
  //         isA<ImpossibleSplitException>(),
  //         hasMessage('The given chunks made it impossible to split.')
  //       ])));
  //   splitControl = SplitControl([
  //     {
  //       'Marion Smith',
  //       'Donald Tlougan',
  //       'Kathleen Fitzgerald',
  //       'Jim Parkman',
  //       'Janet Brown',
  //       'Sally Downie',
  //       'Sandra Pickar',
  //       'Lynn Solomita',
  //       'Ken Pickar',
  //     },
  //     {
  //       'Jim North',
  //       'Maria Ruiz',
  //       'Judy Close',
  //       'Gloria Dumais',
  //       'Ralph Brown',
  //       'Ken Meyer',
  //       'Elizabeth Brown',
  //       'Judy North',
  //     }
  //   ], [
  //     'Marion Smith',
  //     'Donald Tlougan',
  //     'Kathleen Fitzgerald',
  //     'Jim Parkman',
  //     'Janet Brown',
  //     'Sally Downie',
  //     'Sandra Pickar',
  //     'Lynn Solomita',
  //     'Ken Pickar',
  //     'Jim North',
  //     'Maria Ruiz',
  //     'Judy Close',
  //     'Gloria Dumais',
  //     'Ralph Brown',
  //     'Ken Meyer',
  //     'Elizabeth Brown',
  //     'Judy North',
  //     'Norman Stockwell',
  //     'Marilyn Landau',
  //     'Allan Conrad',
  //     'Helen Stockwell'
  //   ], 5, 9);
  //   expect(
  //       () => splitControl.generateRandomGene(),
  //       throwsA(allOf([
  //         isA<ImpossibleSplitException>(),
  //         hasMessage('The given chunks made it impossible to split.')
  //       ])));
  // });
}
