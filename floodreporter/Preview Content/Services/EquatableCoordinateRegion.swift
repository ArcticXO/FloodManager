//
//  EquatableCoordinateRegion.swift
//  floodreporter
//
//  Created by Ali Al Abdullah on 04/02/2025.
//


import MapKit

struct EquatableCoordinateRegion: Equatable {
    var region: MKCoordinateRegion

    static func == (lhs: EquatableCoordinateRegion, rhs: EquatableCoordinateRegion) -> Bool {
        return lhs.region.center.latitude == rhs.region.center.latitude &&
               lhs.region.center.longitude == rhs.region.center.longitude &&
               lhs.region.span.latitudeDelta == rhs.region.span.latitudeDelta &&
               lhs.region.span.longitudeDelta == rhs.region.span.longitudeDelta
    }
}