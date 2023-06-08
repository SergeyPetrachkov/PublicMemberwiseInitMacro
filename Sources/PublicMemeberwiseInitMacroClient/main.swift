import PublicMemeberwiseInitMacro

@publicMemberwiseInit
final class Sample {
    var x: Int
    let y: Double

    init() {
        x = 2
        y = 3
    }
}

let sample = Sample(x: 1, y: 2)

print(sample)
