// Included inside the pinned WDA UITestingUITests implementation for bounded
// XCTest replay over Apple's paired transport. No HTTP listener is started.
// REFERENCE_PLAN is a JSON array passed via xctestrun EnvironmentVariables.
- (void)testReferencePlan
{
  self.continueAfterFailure = NO;
  NSDictionary *env = NSProcessInfo.processInfo.environment;
  NSString *bundle = env[@"REFERENCE_BUNDLE"] ?: @"com.openai.chat";
  FBConfiguration.sharedInstance.currentDisplayId = @([(env[@"REFERENCE_DISPLAY"] ?: @"2") longLongValue]);
  NSString *json = env[@"REFERENCE_PLAN"] ?: @"[]";
  NSError *error = nil;
  NSArray *plan = [NSJSONSerialization JSONObjectWithData:([json dataUsingEncoding:NSUTF8StringEncoding] ?: NSData.data) options:NSJSONReadingFragmentsAllowed error:&error];
  XCTAssertNil(error, @"Native reference operation failed");
  XCTAssertTrue([plan isKindOfClass:NSArray.class], @"Reference plan must be an array");
  XCUIApplication *app = [[XCUIApplication alloc] initWithBundleIdentifier:bundle];
  [app activate];
  XCTAssertTrue([app waitForState:XCUIApplicationStateRunningForeground timeout:15], @"Reference app must be foreground");
  NSUInteger index = 0;
  for (NSDictionary *step in plan) {
    NSString *action = step[@"action"];
    if ([action isEqualToString:@"tap"] || [action isEqualToString:@"hold"]) {
      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"label == %@ OR identifier == %@", step[@"label"], step[@"label"]];
      XCUIElementQuery *query = [app.buttons matchingPredicate:predicate];
      if (query.count == 0) query = [[app descendantsMatchingType:XCUIElementTypeAny] matchingPredicate:predicate];
      NSMutableArray *matches = [NSMutableArray array];
      for (XCUIElement *candidate in query.allElementsBoundByIndex) {
        if (candidate.hittable) [matches addObject:candidate];
      }
      XCTAssertEqual(matches.count, 1, @"Re-resolve exactly one visible control before input: %@", step[@"label"]);
      XCUIElement *element = matches.firstObject;
      if ([action isEqualToString:@"hold"]) [element pressForDuration:1.0]; else [element tap];
    } else if ([action isEqualToString:@"type"]) {
      [app typeText:step[@"text"] ?: @""];
    } else if ([action isEqualToString:@"point"]) {
      NSArray *point = step[@"at"];
      XCUICoordinate *coordinate = [[app coordinateWithNormalizedOffset:CGVectorMake(0, 0)] coordinateWithOffset:CGVectorMake([point[0] doubleValue], [point[1] doubleValue])];
      [coordinate tap];
    } else if ([action isEqualToString:@"drag"]) {
      NSArray *from = step[@"from"], *to = step[@"to"];
      XCUICoordinate *origin = [app coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
      [[origin coordinateWithOffset:CGVectorMake([from[0] doubleValue], [from[1] doubleValue])] pressForDuration:0.05 thenDragToCoordinate:[origin coordinateWithOffset:CGVectorMake([to[0] doubleValue], [to[1] doubleValue])]];
    } else if ([action isEqualToString:@"wait"]) {
      [NSThread sleepForTimeInterval:MIN(20, [step[@"seconds"] doubleValue])];
    } else {
      XCTAssertTrue([action isEqualToString:@"capture"], @"Unknown plan action");
    }
    NSString *name = [NSString stringWithFormat:@"%02lu-%@", (unsigned long)index++, step[@"name"] ?: action];
    XCTAttachment *tree = [XCTAttachment attachmentWithString:app.debugDescription];
    tree.name = [name stringByAppendingString:@"-accessibility"];
    tree.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:tree];
    XCUIScreen *screen = [NSClassFromString(@"FBScreen") currentScreenWithError:&error];
    XCTAssertNil(error, @"Native reference operation failed");
    XCTAttachment *pixels = [XCTAttachment attachmentWithScreenshot:screen.screenshot];
    pixels.name = name;
    pixels.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:pixels];
  }
}
