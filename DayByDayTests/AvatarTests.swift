import Testing
import UIKit
@testable import DayByDay

struct AvatarTests {
    @Test(arguments: AvatarAnimal.allCases) func symbolExists(_ avatar: AvatarAnimal) {
        #expect(UIImage(systemName: avatar.symbol) != nil)
    }
}
