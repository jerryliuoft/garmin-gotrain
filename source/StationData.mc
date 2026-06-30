import Toybox.Lang;

(:background, :glance)
class StationData {

    static function getRoutes() as Dictionary {
        return {
            0 => "Lakeshore West",
            1 => "Lakeshore East",
            2 => "Kitchener",
            3 => "Barrie",
            4 => "Milton",
            5 => "Richmond Hill",
            6 => "Stouffville"
        };
    }

    static function getStationNames() as Dictionary {
        return {
            0 => "Union", 1 => "Clarkson", 2 => "Port Credit", 3 => "Oakville", 4 => "Bronte",
            5 => "Appleby", 6 => "Burlington", 7 => "Aldershot", 8 => "Hamilton", 9 => "West Harbour",
            10 => "Pickering", 11 => "Ajax", 12 => "Whitby", 13 => "Oshawa",
            14 => "Weston", 15 => "Malton", 16 => "Bramalea", 17 => "Brampton", 18 => "Mount Pleasant",
            19 => "Bloor", 20 => "Georgetown", 21 => "Acton", 22 => "Guelph", 23 => "Kitchener",
            24 => "Downsview Park", 25 => "Rutherford", 26 => "Maple", 27 => "King City",
            28 => "Aurora", 29 => "Newmarket", 30 => "East Gwillimbury", 31 => "Bradford",
            32 => "Barrie South", 33 => "Allandale Waterfront",
            34 => "Kipling", 35 => "Dixie", 36 => "Cooksville", 37 => "Erindale",
            38 => "Streetsville", 39 => "Meadowvale", 40 => "Lisgar", 41 => "Milton",
            42 => "Oriole", 43 => "Old Cummer", 44 => "Langstaff", 45 => "Richmond Hill",
            46 => "Gormley", 47 => "Bloomington",
            48 => "Kennedy", 49 => "Agincourt", 50 => "Milliken", 51 => "Unionville",
            52 => "Centennial", 53 => "Markham", 54 => "Mount Joy", 55 => "Stouffville",
            56 => "Old Elm"
        };
    }

    static function getStationCodes() as Dictionary {
        return {
            0 => "UN", 1 => "CL", 2 => "PO", 3 => "OA", 4 => "BR",
            5 => "AP", 6 => "BU", 7 => "AL", 8 => "HA", 9 => "WR",
            10 => "PIN", 11 => "AJ", 12 => "WH", 13 => "OS",
            14 => "WE", 15 => "MA", 16 => "BRAM", 17 => "BRM", 18 => "MO",
            19 => "BL", 20 => "GE", 21 => "AC", 22 => "GL", 23 => "KI",
            24 => "DW", 25 => "RU", 26 => "MP", 27 => "KC",
            28 => "AU", 29 => "NE", 30 => "EG", 31 => "BD",
            32 => "BS", 33 => "AD",
            34 => "KP", 35 => "DI", 36 => "CO", 37 => "ER",
            38 => "SR", 39 => "ME", 40 => "LS", 41 => "ML",
            42 => "OR", 43 => "OL", 44 => "LA", 45 => "RI",
            46 => "GO", 47 => "BM",
            48 => "KE", 49 => "AG", 50 => "MK", 51 => "UI",
            52 => "CE", 53 => "MR", 54 => "MJ", 55 => "ST",
            56 => "LI"
        };
    }

    static function getStationsForRoute(routeId as Number) as Array<Number> {
        if (routeId == 0) {
            return [0, 2, 1, 3, 4, 5, 6, 7, 8, 9];
        } else if (routeId == 1) {
            return [0, 10, 11, 12, 13];
        } else if (routeId == 2) {
            return [0, 19, 14, 15, 16, 17, 18, 20, 21, 22, 23];
        } else if (routeId == 3) {
            return [0, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33];
        } else if (routeId == 4) {
            return [0, 34, 35, 36, 37, 38, 39, 40, 41];
        } else if (routeId == 5) {
            return [0, 42, 43, 44, 45, 46, 47];
        } else if (routeId == 6) {
            return [0, 48, 49, 50, 51, 52, 53, 54, 55, 56];
        }
        return [0];
    }

    static function getStationName(id as Number) as String {
        var names = getStationNames();
        var name = names.get(id);
        return name != null ? (name as String) : "Unknown";
    }

    static function getStationNameFromCode(code as String) as String {
        var codes = getStationCodes();
        var keys = codes.keys();
        for (var i = 0; i < keys.size(); i++) {
            var k = keys[i] as Number;
            if (codes.get(k).equals(code)) {
                return getStationName(k);
            }
        }
        return code;
    }

    static function getStationCode(id as Number) as String {
        var codes = getStationCodes();
        var code = codes.get(id);
        return code != null ? (code as String) : "UN";
    }
}
