import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: RecordingStore
    @Binding var selectedDateFilter: DateFilter
    @Binding var selectedTag: String?
    @Binding var searchText: String

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search recordings...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary)

            Divider()

            List {
                // Date filters
                Section("Library") {
                    ForEach(DateFilter.allCases) { filter in
                        Button {
                            selectedDateFilter = filter
                            selectedTag = nil
                        } label: {
                            HStack {
                                Label(filter.rawValue, systemImage: iconForFilter(filter))
                                Spacer()
                                Text("\(store.count(for: filter))")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 2)
                        .background(
                            selectedTag == nil && selectedDateFilter == filter
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                        .cornerRadius(4)
                    }
                }

                // Tags
                if !store.allTags.isEmpty {
                    Section("Tags") {
                        ForEach(store.allTags, id: \.tag) { item in
                            Button {
                                if selectedTag == item.tag {
                                    selectedTag = nil
                                } else {
                                    selectedTag = item.tag
                                    selectedDateFilter = .all
                                }
                            } label: {
                                HStack {
                                    Label(item.tag, systemImage: "tag")
                                    Spacer()
                                    Text("\(item.count)")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 2)
                            .background(
                                selectedTag == item.tag
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.clear
                            )
                            .cornerRadius(4)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 180)
    }

    private func iconForFilter(_ filter: DateFilter) -> String {
        switch filter {
        case .all: return "tray.full"
        case .today: return "calendar"
        case .thisWeek: return "calendar.badge.clock"
        case .thisMonth: return "calendar.circle"
        }
    }
}
