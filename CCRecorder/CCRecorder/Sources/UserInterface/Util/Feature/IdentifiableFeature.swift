
protocol IdentifiableFeature: Hashable, Identifiable where ID == Self {}

extension IdentifiableFeature {

    var id: Self { self }

}
