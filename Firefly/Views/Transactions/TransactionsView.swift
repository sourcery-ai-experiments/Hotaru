//
//  TransactionsView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/15.
//

import SwiftUI

enum TransactionsFilterType: String {
    case all = "All"
    case withdrawal = "Withdrawal"
    case deposit = "Deposit"
    case expense = "Expense"
    case transfer = "Transfer"
}

@MainActor
struct TransactionsView: View {
    @StateObject private var transactions = TransactionsViewModel()
    @State private var filterType: TransactionsFilterType = .all
    @State var addSheetShown = false
    @State private var filterExpanded = false
    @State private var isLoading = false
    @State private var shouldRefresh: Bool? = false  //Used to refresh after the create page is dismissed.

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                filterSection
                    .padding()
                if isLoading {
                    LoadingSpinner()
                } else {
                    List {
                        ForEach(transactions.transactions?.data ?? [], id: \.id) {
                            transactionData in
                            TransactionsRow(transaction: transactionData)
                                //}
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)

                            //}
                        }

                        if transactions.hasMorePages {
                            Button(action: {
                                Task {
                                    await transactions.fetchTransactions(loadMore: true)
                                }
                            }) {
                                Text("Load More")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .listRowSeparator(.hidden)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    //.listRowSpacing(-10)
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
            }
            .background(Color.clear)
            .onAppear {
                if transactions.transactions == nil {
                    Task {
                        isLoading = true
                        await transactions.fetchTransactions()
                        isLoading = false
                    }
                }
            }
            .refreshable {
                applyDateFilter()
            }
            .navigationTitle("Transactions")
            .toolbar {
                Button(action: {
                    addSheetShown = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .padding(6)
                        .fontWeight(.heavy)
                }
            }
        }
        .sheet(
            isPresented: $addSheetShown,
            onDismiss: {
                if shouldRefresh! {
                    Task {
                        applyDateFilter()
                        shouldRefresh = false
                    }
                }
            }
        ) {
            TransactionCreate(shouldRefresh: $shouldRefresh).background(.ultraThinMaterial)
        }
    }

    private var filterSection: some View {
        VStack {
            Button(action: {
                withAnimation {
                    filterExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Filter")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: filterExpanded ? "chevron.up" : "chevron.down")
                }
                .contentShape(Rectangle())  // This ensures the entire HStack is tappable
            }
            .buttonStyle(PlainButtonStyle())  // This removes the default button styling

            if filterExpanded {
                VStack(alignment: .leading, spacing: 10) {

                    DatePicker(
                        "Start Date", selection: $transactions.startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    DatePicker(
                        "End Date", selection: $transactions.endDate, displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    HStack {
                        Text("Type")
                        Spacer()
                        Picker("Type", selection: $transactions.type) {
                            ForEach(TransactionTypes.allCases) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                    }

                    HStack {
                        Button("Apply Filter") {
                            applyDateFilter()
                        }
                        Spacer()
                        Button("Reset") {
                            transactions.resetDates()
                            applyDateFilter()
                        }
                    }
                }

                .padding(.top)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }

    private func applyDateFilter(isRefreshing: Bool = false) {
        Task {
            await transactions.fetchTransactions()
        }
        withAnimation {
            filterExpanded = false
        }
    }
}

struct TransactionsRow: View {
    var transaction: TransactionsDatum
    @State private var isActiveNav: Bool = true
    var showDate = true
    var showAccount = true
    var body: some View {
        ZStack {
            NavigationLink(
                destination: TransactionDetail(transaction: transaction)
            ) { EmptyView() }
            .opacity(0.0).buttonStyle(PlainButtonStyle())
            VStack {
                HStack {
                    Image(
                        systemName: transactionTypeIcon(
                            transaction.attributes?.transactions?.first?.type ?? "unknown")
                    )
                    .foregroundStyle(
                        transactionTypeStyle(
                            transaction.attributes?.transactions?.first?.type ?? "unknown")
                    )
                    .frame(width: 60, height: 60)
                    .font(.system(size: 30))

                    VStack(alignment: .leading) {
                        Text(
                            transactionMainTitle(transaction)
                        )
                        .font(.headline)
                        .lineLimit(1)
                        Text(
                            formatAmount(
                                calculateTransactionTotalAmount(transaction),
                                symbol: transaction.attributes?.transactions?.first?.currencySymbol)
                        )
                        .font(.largeTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Spacer()

                        //In case of split Transaction
                        if isSplitTransaction(transaction) {
                            if showAccount {
                                SplitBadge()
                            }
                        } else {
                            if showAccount {
                                if transaction.attributes?.transactions?.first?.sourceName != nil {
                                    Text(
                                        transaction.attributes?.transactions?.first?.sourceName
                                            ?? "Source Error"
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                }
                            }
                        }

                        if showDate {
                            Text(formatDate(transaction.attributes?.transactions?.first?.date))
                                .foregroundStyle(.gray)
                        }

                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)  // Add padding inside the HStack
            }
        }
        .background(.ultraThinMaterial)  // Add a background color if needed
        .cornerRadius(12)  // Round the corners
        .padding(.horizontal)  // Add horizontal padding to the entire row
        .padding(.vertical, 2)
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString,
            let date = ISO8601DateFormatter().date(from: dateString)
        else {
            return "Unknown Date"
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(date, equalTo: now, toGranularity: .day) {
            return "Today"
        }

        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"  // Full name of the day
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }

}

struct SplitBadge: View {
    let text: String
    let imageName: String
    let font: Font
    let foregroundStyle: Color
    let backgroundColor: Color

    init(
        text: String = "Split",
        imageName: String = "arrow.branch",
        font: Font = .subheadline,
        foregroundStyle: Color = .white,
        backgroundColor: Color = .green
    ) {
        self.text = text
        self.imageName = imageName
        self.font = font
        self.foregroundStyle = foregroundStyle
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        HStack {
            Image(systemName: imageName)
            Text(text)
        }
        .font(font)
        .foregroundStyle(foregroundStyle)
        .padding(.horizontal, 10)
        .padding(.vertical, 1)
        .background(backgroundColor)
        .clipShape(Capsule())
    }
}

//struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsView(transactions: TransactionsViewModel.mock())
//    }
//}
