from _loader import m
def test_version_routes_haiku():         assert m.route_scan("version") == "haiku"
def test_substantive_routes_escalated(): assert m.route_scan("substantive") == "escalated"
def test_new_routes_escalated():         assert m.route_scan("new") == "escalated"
