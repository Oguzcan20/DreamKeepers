import XCTest
@testable import Dreamkeepers

final class LevelSystemTests: XCTestCase {
    func testExpToNextLevelGrowsWithLevel() {
        let lvl1 = LevelSystem.expToNextLevel(from: 1)
        let lvl10 = LevelSystem.expToNextLevel(from: 10)
        XCTAssertGreaterThan(lvl10, lvl1)
    }

    func testApplyExpWithNoLevelUp() {
        let result = LevelSystem.applyExp(5, level: 1, exp: 0)
        XCTAssertEqual(result.finalLevel, 1)
        XCTAssertEqual(result.finalExp, 5)
        XCTAssertEqual(result.levelsGained, 0)
    }

    func testApplyExpSingleLevelUp() {
        let required = LevelSystem.expToNextLevel(from: 1)
        let result = LevelSystem.applyExp(required, level: 1, exp: 0)
        XCTAssertEqual(result.finalLevel, 2)
        XCTAssertEqual(result.finalExp, 0)
        XCTAssertEqual(result.levelsGained, 1)
    }

    func testApplyExpMultipleLevelUps() {
        let required1 = LevelSystem.expToNextLevel(from: 1)
        let required2 = LevelSystem.expToNextLevel(from: 2)
        let result = LevelSystem.applyExp(required1 + required2 + 3, level: 1, exp: 0)
        XCTAssertEqual(result.finalLevel, 3)
        XCTAssertEqual(result.finalExp, 3)
        XCTAssertEqual(result.levelsGained, 2)
    }

    func testCannotExceedMaxLevel() {
        let result = LevelSystem.applyExp(1_000_000, level: LevelSystem.maxLevel - 1, exp: 0)
        XCTAssertEqual(result.finalLevel, LevelSystem.maxLevel)
        XCTAssertEqual(result.finalExp, 0)
    }
}
