import SwiftUI

struct GoogleLogoView: View {
    var body: some View {
        Canvas { context, size in
            let scale = size.width / 48

            // Red part
            let gPath1 = Path { path in
                path.move(to: CGPoint(x: 24, y: 9.5))
                path.addCurve(
                    to: CGPoint(x: 33.21, y: 13.1),
                    control1: CGPoint(x: 27.54, y: 9.5),
                    control2: CGPoint(x: 30.71, y: 10.72)
                )
                path.addLine(to: CGPoint(x: 40.06, y: 6.25))
                path.addCurve(
                    to: CGPoint(x: 24, y: 0),
                    control1: CGPoint(x: 35.9, y: 2.38),
                    control2: CGPoint(x: 30.47, y: 0)
                )
                path.addCurve(
                    to: CGPoint(x: 2.56, y: 13.22),
                    control1: CGPoint(x: 14.62, y: 0),
                    control2: CGPoint(x: 6.51, y: 5.38)
                )
                path.addLine(to: CGPoint(x: 10.54, y: 19.41))
                path.addCurve(
                    to: CGPoint(x: 24, y: 9.5),
                    control1: CGPoint(x: 12.43, y: 13.72),
                    control2: CGPoint(x: 17.74, y: 9.5)
                )
                path.closeSubpath()
            }

            // Blue part
            let gPath2 = Path { path in
                path.move(to: CGPoint(x: 46.98, y: 24.55))
                path.addCurve(
                    to: CGPoint(x: 46.6, y: 20),
                    control1: CGPoint(x: 46.98, y: 22.98),
                    control2: CGPoint(x: 46.83, y: 21.46)
                )
                path.addLine(to: CGPoint(x: 24, y: 20))
                path.addLine(to: CGPoint(x: 24, y: 29.02))
                path.addLine(to: CGPoint(x: 36.94, y: 29.02))
                path.addCurve(
                    to: CGPoint(x: 32.16, y: 36.2),
                    control1: CGPoint(x: 36.36, y: 31.98),
                    control2: CGPoint(x: 34.68, y: 34.5)
                )
                path.addLine(to: CGPoint(x: 39.89, y: 42.2))
                path.addCurve(
                    to: CGPoint(x: 46.98, y: 24.55),
                    control1: CGPoint(x: 44.4, y: 38.02),
                    control2: CGPoint(x: 46.98, y: 31.84)
                )
                path.closeSubpath()
            }

            // Yellow part
            let gPath3 = Path { path in
                path.move(to: CGPoint(x: 10.53, y: 28.59))
                path.addCurve(
                    to: CGPoint(x: 9.77, y: 24),
                    control1: CGPoint(x: 10.05, y: 27.14),
                    control2: CGPoint(x: 9.77, y: 25.6)
                )
                path.addCurve(
                    to: CGPoint(x: 10.53, y: 19.41),
                    control1: CGPoint(x: 9.77, y: 22.4),
                    control2: CGPoint(x: 10.04, y: 20.86)
                )
                path.addLine(to: CGPoint(x: 2.55, y: 13.22))
                path.addCurve(
                    to: CGPoint(x: 0, y: 24),
                    control1: CGPoint(x: 0.92, y: 16.46),
                    control2: CGPoint(x: 0, y: 20.12)
                )
                path.addCurve(
                    to: CGPoint(x: 2.56, y: 34.78),
                    control1: CGPoint(x: 0, y: 27.88),
                    control2: CGPoint(x: 0.92, y: 31.54)
                )
                path.addLine(to: CGPoint(x: 10.53, y: 28.59))
                path.closeSubpath()
            }

            // Green part
            let gPath4 = Path { path in
                path.move(to: CGPoint(x: 24, y: 48))
                path.addCurve(
                    to: CGPoint(x: 39.89, y: 42.19),
                    control1: CGPoint(x: 30.48, y: 48),
                    control2: CGPoint(x: 35.93, y: 45.87)
                )
                path.addLine(to: CGPoint(x: 32.16, y: 36.19))
                path.addCurve(
                    to: CGPoint(x: 24, y: 38.49),
                    control1: CGPoint(x: 30.01, y: 37.64),
                    control2: CGPoint(x: 27.24, y: 38.49)
                )
                path.addCurve(
                    to: CGPoint(x: 10.53, y: 28.58),
                    control1: CGPoint(x: 17.74, y: 38.49),
                    control2: CGPoint(x: 12.43, y: 34.27)
                )
                path.addLine(to: CGPoint(x: 2.55, y: 34.77))
                path.addCurve(
                    to: CGPoint(x: 24, y: 48),
                    control1: CGPoint(x: 6.51, y: 42.62),
                    control2: CGPoint(x: 14.62, y: 48)
                )
                path.closeSubpath()
            }

            context.scaleBy(x: scale, y: scale)

            // Fill each path with its respective color
            context.fill(gPath1, with: .color(.red))
            context.fill(gPath2, with: .color(.blue))
            context.fill(gPath3, with: .color(.yellow))
            context.fill(gPath4, with: .color(.green))
        }
    }
}
