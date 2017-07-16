import XCTest
import ReactiveSwift
import Result

private func _measure(times: UInt64 = 2_000_000, label: String = #function, _ action: (() -> UInt64) -> Void) {
	var result: UInt64 = 0
	var minResult: UInt64 = .max

	for i in 0 ..< times {
		var start: UInt64!
		action {
			start = mach_absolute_time()
			return i
		}
		let end = mach_absolute_time()

		let r = (end - start)
		result += r
		minResult = min(minResult, r)
	}

	var base = mach_timebase_info()
	_ = withUnsafeMutablePointer(to: &base, mach_timebase_info)

	let ns = (result / times) / UInt64(base.denom) * UInt64(base.numer)
	let minNs = minResult / UInt64(base.denom) * UInt64(base.numer)

	print("@\(label): avg \(ns) ns; min \(minNs) ns")
}

private func _measureAndStart(times: UInt64 = 2_000_000, label: String = #function, _ action: () -> Void) {
	return _measure(times: times, label: label) { start in
		_ = start()
		action()
	}
}

class Test: XCTestCase {
	func testLiftMapFilter() {
		let t = SignalProducer<Int, NoError>(Array(repeating: 1, count: 8))
			.lift { $0.map { $0 } }
			.lift { $0.filter { $0 % 2 == 0 } }

		_measureAndStart {
			t.start { _ in }
		}
	}

	func testEventTransformingCoreMapFilter() {
		let t = SignalProducer<Int, NoError>(Array(repeating: 1, count: 8))
			.map { $0 }.filter { $0 % 2 == 0 }

		_measureAndStart(times: 500_000) {
			t.start()
		}
	}

	func testValue() {
		let t = SignalProducer<Int, NoError>(value: 1)
		_measureAndStart {
			t.start { _ in }
		}
	}

	func testSequence() {
		let t = SignalProducer<Int, NoError>(Array(repeating: 1, count: 32))
		_measureAndStart(times: 500_000) {
			t.start()
		}
	}
}
