import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .foregroundStyle(.tint)

                    Text("My Person CRM").font(.largeTitle.bold())

                    Text("A personal CRM. Pick the people who matter, log how you stay in touch, and let the calendar surface what's coming up.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("From the developer").font(.headline)
                        Text("Built alongside Claude as part of Claude's X26 Swift6 Bible. The source is on GitHub — clone it, read it, build your own.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 8) {
                        Link(destination: URL(string: "https://fluharty.me/privacy")!) {
                            Label("Privacy", systemImage: "lock.shield")
                        }
                        Link(destination: URL(string: "https://github.com/fluhartyml/My-Person-CRM")!) {
                            Label("Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                        Link(destination: URL(string: "mailto:michael@fluharty.com?subject=My%20Person%20CRM%20Feedback")!) {
                            Label("Send Feedback", systemImage: "envelope")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding()
            }
            .navigationTitle("About")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
