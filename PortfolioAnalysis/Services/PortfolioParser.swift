import Foundation

// MARK: - Parse Result

struct ParseResult {
    let holdings: [Holding]
    let errors: [String]
    let skippedRows: Int
}

// MARK: - Portfolio Parser

enum PortfolioParser {

    // MARK: Column name aliases (lowercase)

    private static let symbolAliases      = ["symbol", "ticker", "stock", "cusip"]
    private static let nameAliases        = ["name", "security", "description", "security name", "fund name", "investment name"]
    private static let sharesAliases      = ["shares", "quantity", "qty", "units", "amount", "# shares", "number of shares"]
    private static let costBasisAliases   = ["cost basis per share", "cost per share", "avg cost", "average cost",
                                             "unit cost", "cost basis/share", "average price paid", "avg price", "price paid"]
    private static let priceAliases       = ["last price", "current price", "price", "market price", "last", "close",
                                             "mkt price", "closing price"]
    private static let accountNameAliases = ["account", "account name", "acct", "acct name"]
    private static let accountTypeAliases = ["account type", "type of account", "ira", "account category", "acct type"]
    private static let assetTypeAliases   = ["type", "asset type", "security type", "investment type", "security type code"]

    // MARK: - Public API

    static func parse(_ text: String) -> ParseResult {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard lines.count >= 2 else {
            return ParseResult(
                holdings: [],
                errors: ["Need at least a header row and one data row."],
                skippedRows: 0
            )
        }

        // Parse header
        let headers = lines[0]
            .components(separatedBy: "\t")
            .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        guard let symbolIdx = findIndex(headers, aliases: symbolAliases) else {
            return ParseResult(
                holdings: [],
                errors: ["Could not find a Symbol/Ticker column. Make sure the first row is a header."],
                skippedRows: lines.count - 1
            )
        }

        let nameIdx        = findIndex(headers, aliases: nameAliases)
        let sharesIdx      = findIndex(headers, aliases: sharesAliases)
        let costBasisIdx   = findIndex(headers, aliases: costBasisAliases)
        let priceIdx       = findIndex(headers, aliases: priceAliases)
        let accountNameIdx = findIndex(headers, aliases: accountNameAliases)
        let accountTypeIdx = findIndex(headers, aliases: accountTypeAliases)
        let assetTypeIdx   = findIndex(headers, aliases: assetTypeAliases)

        var holdings:   [Holding] = []
        var errors:     [String]  = []
        var skipped = 0

        for (rowNum, line) in lines.dropFirst().enumerated() {
            let cols = line.components(separatedBy: "\t")

            guard cols.count > symbolIdx else { skipped += 1; continue }

            let symbol = col(cols, at: symbolIdx)?.uppercased() ?? ""
            guard !symbol.isEmpty else { skipped += 1; continue }

            let name             = col(cols, at: nameIdx) ?? symbol
            let shares           = double(col(cols, at: sharesIdx)) ?? 1.0
            let costBasisPerShare = double(col(cols, at: costBasisIdx)) ?? 0.0
            let currentPrice     = double(col(cols, at: priceIdx)) ?? 0.0
            let accountName      = col(cols, at: accountNameIdx) ?? "Default Account"
            let accountTypeStr   = col(cols, at: accountTypeIdx) ?? ""
            let assetTypeStr     = col(cols, at: assetTypeIdx) ?? ""

            let accountType = parseAccountType(accountTypeStr)
            let assetType   = parseAssetType(assetTypeStr, symbol: symbol)

            if currentPrice == 0 && assetType != .cash {
                errors.append("Row \(rowNum + 2): \(symbol) has a price of $0.00 — verify your data.")
            }

            holdings.append(Holding(
                symbol: symbol,
                name: name,
                shares: shares,
                costBasisPerShare: costBasisPerShare,
                currentPrice: currentPrice,
                accountName: accountName,
                accountType: accountType,
                assetType: assetType
            ))
        }

        return ParseResult(holdings: holdings, errors: errors, skippedRows: skipped)
    }

    // MARK: - Private Helpers

    private static func findIndex(_ headers: [String], aliases: [String]) -> Int? {
        for (i, header) in headers.enumerated() {
            for alias in aliases where header == alias || header.contains(alias) || alias.contains(header) {
                return i
            }
        }
        return nil
    }

    private static func col(_ cols: [String], at index: Int?) -> String? {
        guard let idx = index, idx < cols.count else { return nil }
        let v = cols[idx].trimmingCharacters(in: .whitespaces)
        return v.isEmpty ? nil : v
    }

    private static func double(_ str: String?) -> Double? {
        guard let s = str else { return nil }
        let cleaned = s
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    private static func parseAccountType(_ raw: String) -> AccountType {
        let s = raw.lowercased()
        if s.contains("traditional") || (s.contains("ira") && !s.contains("roth")) {
            return .traditionalIRA
        }
        return .nonIRA
    }

    private static func parseAssetType(_ raw: String, symbol: String) -> AssetType {
        let s = raw.lowercased()
        if s.contains("cash") || symbol == "CASH" || symbol.hasPrefix("MM") { return .cash }
        if s.contains("mutual") || s.contains("fund")                        { return .mutualFund }
        if s.contains("etf") || s.contains("exchange traded")                { return .etf }
        // Heuristic: 5-letter symbols ending in X are usually mutual funds
        if symbol.count == 5 && symbol.hasSuffix("X")                        { return .mutualFund }
        return .stock
    }
}
