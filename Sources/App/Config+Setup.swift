import PostgreSQLProvider

extension Config {
    public func setup() throws {
        
        // allow fuzzy conversions for these types
        // (add your own types here)
        Node.fuzzy = [Row.self, JSON.self, Node.self]
        
        try setupProviders()
        try setupPreparations()
        try setupConfigurables()
    }
    
    /// Configure providers
    private func setupProviders() throws {
        try addProvider(PostgreSQLProvider.Provider.self)
    }
    
    /// Add all models that should have their
    /// schemas prepared before the app boots
    private func setupPreparations() throws {
        preparations.append(User.self)
        preparations.append(Log.self)
    }
    
    private func setupConfigurables() throws {
        let auth = try AuthMiddleware(config: self)
        addConfigurable(middleware: auth, name: "auth")
        try APNSCenter.shared.config(with: self)
    }
}
