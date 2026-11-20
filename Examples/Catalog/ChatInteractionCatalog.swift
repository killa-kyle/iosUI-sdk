import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI

/// Real native controls exercising the same public models an app uses.
struct ChatInteractionCatalog: View {
  @State private var scroll = StreamScrollCoordinator<String>()
  @State private var activity = ActivityDisclosureStore<String>()
  @State private var messages = Array(20..<60)
  @State private var chunkCount = 0
  @State private var partial = ""
  @State private var streaming = false
  @State private var streamGeneration = 0
  @State private var streamTask: Task<Void, Never>?
  @State private var scrollTask: Task<Void, Never>?
  @State private var draft = ""
  @State private var keyboard: KeyboardViewportSnapshot?
  @State private var posture: ViewportPosture = .compact
  @State private var anchors = ReadingAnchorTracker<String>()
  @State private var visibleAnchorID: String?
  @State private var viewport = BehaviorRect(width: 1, height: 1)
  @State private var layoutRevision: UInt64 = 0
  @State private var activityRevision: UInt64 = 0
  @State private var activityActions = 0
  @FocusState private var composerFocused: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ScrollViewReader { proxy in
      VStack(spacing: 10) {
        HStack {
          Text(scroll.followsLatest ? "Following latest" : "Reading earlier")
            .accessibilityIdentifier("chat-follow-mode")
          Spacer()
          Button("Latest") {
            scroll.followLatest()
            enqueue(.latest, .explicit, proxy, replace: true)
          }
          .accessibilityIdentifier("chat-jump-latest")
        }
        HStack {
          Button(streaming ? "Stop stream" : "Start stream") {
            if streaming { streamTask?.cancel() } else { startStream() }
          }.accessibilityIdentifier("chat-stream")
          Button("Append chunk") { appendChunk() }.accessibilityIdentifier("chat-append")
          Button("Earlier") {
            guard let first = messages.first else { return }
            scroll.beginReading(anchor: anchors.anchor)
            anchors.freeze()
            messages.insert(contentsOf: Array((first - 10)..<first), at: 0)
            restore(viewport, reason: .history, proxy)
          }.accessibilityIdentifier("chat-load-earlier")
        }.font(.caption).buttonStyle(.bordered)
        if !composerFocused {
          HStack {
            Text("Preview layout").font(.caption)
            ForEach([ViewportPosture.compact, .expanded, .tabletop], id: \.rawValue) { value in
              Button(value.rawValue.capitalized) {
                anchors.freeze()
                posture = value
              }
              .accessibilityIdentifier("chat-layout-" + value.rawValue)
            }
          }.font(.caption).buttonStyle(.bordered)
        }
        activityToggle
        GeometryReader { geometry in
          let bounds = BehaviorRect(width: geometry.size.width, height: geometry.size.height)
          let reserved = reservedRegions(bounds)
          let measured = keyboard.flatMap { value -> [BehaviorRect]? in
            abs(value.context.bounds.width - bounds.width) < 0.001
              && abs(value.context.bounds.height - bounds.height) < 0.001
              && value.context.posture == posture
              ? value.availableRegions : nil
          }
          let regions =
            measured ?? ViewportGeometry.availableRegions(in: bounds, excluding: reserved)
          let ordered = regions.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }
          if let content = ordered.first {
            let input = posture == .tabletop ? (ordered.last ?? content) : content
            let separate = input != content
            let height = max(0, content.height - (separate ? 0 : 60))
            let listBounds = BehaviorRect(width: content.width, height: height)
            ZStack(alignment: .topLeading) {
              ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                  ForEach(messages, id: \.self) { number in
                    Text(
                      "Message \(number). This is a local sample for reading while new content arrives."
                    )
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    .id("message-\(number)").accessibilityIdentifier("chat-message-\(number)")
                    .behaviorReadingAnchor(
                      "message-\(number)", in: .named("chat-viewport"), viewport: listBounds,
                      layoutRevision: layoutRevision, restorationTarget: scroll.restorationTarget)
                  }
                  VStack(alignment: .leading) { activityDetails }
                    .id("chat-activity")
                    .behaviorReadingAnchor(
                      "chat-activity", in: .named("chat-viewport"), viewport: listBounds,
                      layoutRevision: layoutRevision, restorationTarget: scroll.restorationTarget)
                  if !partial.isEmpty {
                    Text(partial).accessibilityIdentifier("chat-partial").id("chat-partial")
                      .behaviorReadingAnchor(
                        "chat-partial", in: .named("chat-viewport"), viewport: listBounds,
                        layoutRevision: layoutRevision, restorationTarget: scroll.restorationTarget)
                  }
                  Color.clear.frame(height: 1).id("chat-latest")
                }.padding(8)
              }
              .coordinateSpace(name: "chat-viewport")
              .behaviorScrollPhase { observation in
                if observation.phase == .dragging {
                  anchors.resume(in: viewport, layoutRevision: layoutRevision)
                }
                scroll.observePhase(observation.phase, atLatest: observation.atLatest ?? false)
                if observation.phase.holdsAutomaticScrolling { scrollTask?.cancel() }
                if observation.phase == .idle, scroll.followsLatest {
                  enqueue(.latest, .stream, proxy)
                }
              }
              .onPreferenceChange(BehaviorReadingAnchorPreference<String>.self) { measurement in
                guard let measurement, measurement.layoutRevision == layoutRevision else { return }
                if anchors.record(measurement) { visibleAnchorID = anchors.anchor?.id }
                if let request = scroll.measureRestoration(measurement) { execute(request, proxy) }
              }
              .frame(width: content.width, height: height)
              .offset(x: content.x, y: content.y)
              .accessibilityIdentifier("chat-transcript")
              TextField("Message", text: $draft)
                .textFieldStyle(.roundedBorder).focused($composerFocused)
                .onSubmit { composerFocused = false }
                .frame(width: max(0, input.width - 16), height: 44)
                .position(x: input.x + input.width / 2, y: max(input.y + 22, input.maxY - 28))
                .accessibilityIdentifier("chat-composer")
              ForEach(Array(reserved.enumerated()), id: \.offset) { _, rect in
                Rectangle().fill(.secondary.opacity(0.25))
                  .frame(width: rect.width, height: rect.height).offset(x: rect.x, y: rect.y)
                  .allowsHitTesting(false).accessibilityHidden(true)
              }
            }
            .onAppear {
              restore(listBounds, reason: .initial, proxy)
            }
            .onDisappear {
              anchors.freeze()
              scrollTask?.cancel()
              scroll.cancel()
            }
            .onChange(of: listBounds) { _, next in restore(next, reason: .viewport, proxy) }
          }
          Color.clear.background(
            BehaviorKeyboardObserver(posture: posture, reservedRegions: reserved) {
              keyboard = $0
            }
          ).allowsHitTesting(false)
        }
        if !composerFocused {
          Text("Chunks: \(chunkCount)").accessibilityIdentifier("chat-chunk-count")
          Text("Anchor: \(visibleAnchorID ?? "none")").accessibilityIdentifier("chat-anchor")
          Text("Layout: \(posture.rawValue)").accessibilityIdentifier("chat-layout-value")
          Text("Activity actions: \(activityActions)").accessibilityIdentifier(
            "chat-activity-actions")
          Text("Available panes: \(keyboard?.availableRegions.count ?? 1)")
            .accessibilityIdentifier("chat-pane-count")
          Text(
            "Layout previews simulate reserved regions. The keyboard uses the native layout guide."
          )
          .font(.caption).foregroundStyle(.secondary)
        }
      }.padding(12)
        .onChange(of: chunkCount) { _, _ in enqueue(.latest, .stream, proxy) }
        .onDisappear {
          streamGeneration += 1
          streamTask?.cancel()
          scrollTask?.cancel()
          scroll.cancel()
        }
    }
  }

  @ViewBuilder private var activityToggle: some View {
    let id = "reply"
    Button {
      activityActions += 1
      if activity[id].toggle(running: streaming) == .opened {
        scroll.beginReading(anchor: anchors.anchor)
        scrollTask?.cancel()
      }
    } label: {
      Label(
        "Work details",
        systemImage: activity[id].expanded(running: streaming) ? "chevron.down" : "chevron.right")
        .frame(minHeight: 44)
    }.accessibilityIdentifier("chat-activity-toggle")
      .accessibilityValue(activity[id].expanded(running: streaming) ? "Expanded" : "Collapsed")
  }
  @ViewBuilder private var activityDetails: some View {
    let id = "reply"
    if activity[id].expanded(running: streaming) {
      Text(
        "Received \(chunkCount) chunks. Phase: \(activity.phase(for: id)?.rawValue ?? "pending")"
      )
      .accessibilityIdentifier("chat-activity-details")
    }
  }
  private func reservedRegions(_ bounds: BehaviorRect) -> [BehaviorRect] {
    switch posture {
    case .expanded:
      [BehaviorRect(x: bounds.width / 2 - 6, width: 12, height: bounds.height)]
    case .tabletop:
      [BehaviorRect(y: bounds.height / 2 - 6, width: bounds.width, height: 12)]
    default: []
    }
  }
  private func appendChunk() {
    chunkCount += 1
    partial += "word\(chunkCount) "
    observeActivity(streaming ? .running : .pending)
  }
  private func observeActivity(_ phase: ActivityPhase) {
    activityRevision &+= 1
    activity.observe("reply", phase: phase, revision: activityRevision)
  }
  private func restore(
    _ next: BehaviorRect, reason: StreamScrollCoordinator<String>.Reason, _ proxy: ScrollViewProxy
  ) {
    anchors.freeze()
    if let anchor = anchors.anchor { scroll.remember(anchor) }
    viewport = next
    layoutRevision &+= 1
    if scroll.followsLatest {
      enqueue(.latest, reason, proxy, replace: true)
    } else if let request = scroll.beginAnchorRestoration(
      in: next, layoutRevision: layoutRevision, reason: reason)
    {
      execute(request, proxy)
    } else {
      anchors.resume(in: next, layoutRevision: layoutRevision)
    }
  }
  private func startStream() {
    streamTask?.cancel()
    streamGeneration += 1
    let generation = streamGeneration
    streaming = true
    observeActivity(.running)
    streamTask = Task { @MainActor in
      for _ in 0..<300 {
        do { try await Task.sleep(for: .milliseconds(80)) } catch { break }
        guard !Task.isCancelled, generation == streamGeneration else { break }
        appendChunk()
      }
      guard generation == streamGeneration else { return }
      streaming = false
      observeActivity(Task.isCancelled ? .cancelled : .completed)
    }
  }
  private func enqueue(
    _ target: StreamScrollCoordinator<String>.Target,
    _ reason: StreamScrollCoordinator<String>.Reason, _ proxy: ScrollViewProxy,
    replace: Bool = false
  ) {
    guard let request = scroll.request(target, reason: reason, replacingPending: replace) else {
      return
    }
    execute(request, proxy)
  }
  private func execute(_ request: StreamScrollCoordinator<String>.Request, _ proxy: ScrollViewProxy)
  {
    scrollTask?.cancel()
    scrollTask = Task { @MainActor in
      do {
        try await Task.sleep(for: .milliseconds(45))
        guard scroll.isCurrent(request) else { return }
        var transaction = Transaction(
          animation: request.animated && !reduceMotion ? .easeOut(duration: 0.2) : nil)
        transaction.disablesAnimations = !request.animated || reduceMotion
        withTransaction(transaction) {
          switch request.target {
          case .latest: proxy.scrollTo("chat-latest", anchor: .bottom)
          case .item(let id, let alignment):
            proxy.scrollTo(id, anchor: UnitPoint(x: 0, y: alignment))
          }
        }
      } catch {}
      if scroll.finish(request) {
        scrollTask = nil
        if !scroll.isRestoringAnchor {
          anchors.resume(in: viewport, layoutRevision: layoutRevision)
          visibleAnchorID = anchors.anchor?.id
        }
      }
    }
  }
}
