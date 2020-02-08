import XCTest

final class TipUITests : XCTestCase {

  let pasteBoard = NSPasteboard.general
  let app = XCUIApplication()

  override func setUp() {
    pasteBoard.clearContents()
    pasteBoard.setString("", forType: .string)
  }

  override func tearDown() {
    app.terminate()
  }

  func testGoodProviderClickingOnText() {
    launch(withName: "good_provider")
    popoverElement(withIndex: 0).click()
    XCTAssertEqual("Return TestInput", pasteBoard.string(forType: .string))
  }

  func testGoodProviderClickingOnURL() {
    launch(withName: "good_provider")
    popoverElement(withIndex: 1).click()
    XCTAssertEqual("tanintip://TestInput", pasteBoard.string(forType: .string))
  }

  func testNoProvider() {
    app.launchArguments = ["-test", "TestInput", "-provider", "/tmp/something-doesn-exist.rb"]
    app.launch()
    XCTAssertEqual("/tmp/something-doesn-exist.rb doesn't exist. Please make a provider script. Click to see instruction.", app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String)

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("OpenProviderInstruction", pasteBoard.string(forType: .string))
  }

  func testNoTip() {
    launch(withName: "empty_provider")
    XCTAssertEqual("No tips. You can add tips through your provider script. Click to see the instruction.", app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String)

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("OpenProviderInstruction", pasteBoard.string(forType: .string))
  }

  func testProviderUnexecutable() {
    launch(withName: "unexecutable_provider")
    let value = app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String
    let firstSlash = value.firstIndex(of: "/") ?? value.endIndex
    XCTAssertEqual("Provider isn't executable. Please chmod 755 ", value[..<firstSlash])

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("None", pasteBoard.string(forType: .string))
  }

  func testProvideMalformedJson() {
    launch(withName: "malformed_json_provider")
    XCTAssertEqual("Malformed JSON returned from provider. Click to see logs in Console. You'll need to set the filter Process=Tip.", app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String)

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("OpenConsole", pasteBoard.string(forType: .string))
  }

  func testErrorProvider() {
    launch(withName: "error_provider")
    XCTAssertEqual("Error occurred. Click to see logs in Console. You'll need to set the filter Process=Tip.", app.popovers.children(matching: .any).element(boundBy: 1).firstMatch.value as! String)

    app.popovers.element.click()
    usleep(useconds_t(200 * 1000))
    XCTAssertEqual("OpenConsole", pasteBoard.string(forType: .string))
  }

  func testPerformance() {
    if #available(OSX 10.15, *) {
      measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
        app.launch()
      }
    } else {
      // Fallback on earlier versions
    }
  }

  private func launch(withName: String){
    let file = Bundle(for: type(of: self)).path(forResource: withName, ofType: "rb")
    app.launchArguments = ["-test", "TestInput", "-provider", file!]
    app.launch()
  }

  private func popoverElement(withIndex: Int) -> XCUIElement {
    return app.popovers.element.tableRows.allElementsBoundByIndex[withIndex].cells.firstMatch
  }
}
