const center_x = 117.3;
const center_y = 172.8;
const scale_x = 0.02072;
const scale_y = 0.0205;
var mymap = null
let currentCoords = {x: -1, y: -1};



CUSTOM_CRS = L.extend({}, L.CRS.Simple, {
    projection: L.Projection.LonLat,
    scale: function(zoom) {

        return Math.pow(2, zoom);
    },
    zoom: function(sc) {

        return Math.log(sc) / 0.6931471805599453;
    },
	distance: function(pos1, pos2) {
        var x_difference = pos2.lng - pos1.lng;
        var y_difference = pos2.lat - pos1.lat;
        return Math.sqrt(x_difference * x_difference + y_difference * y_difference);
    },
	transformation: new L.Transformation(scale_x, center_x, -scale_y, center_y),
    infinite: true
});

var	AtlasStyle = L.tileLayer('mapStyles/styleAtlas/{z}/{x}/{y}.jpg', {minZoom: 5,maxZoom: 5,noWrap: true,continuousWorld: false,attribution: 'Online map GTA V',id: 'styleAtlas map',});

var myIcon = L.icon({
  iconUrl: 'blips/1.png',
  iconSize: [40, 40],
  iconAnchor: [20, 40],
});

function createMap() {
  mymap = L.map('map', {
    crs: CUSTOM_CRS,
    minZoom: 5,
    maxZoom: 5,
    Zoom: 5,
    maxNativeZoom: 5,
    preferCanvas: true,
    layers: [AtlasStyle],
    center: [0, 0],
    zoom: 5,
    zoomControl: false,
    attributionControl: false,
    dragging: false,
    boxZoom: false,
    scrollWheelZoom: false,
});
}

function closemap() {
  mymap = null
}

function goToCoords(x,y){
  if (currentCoords.x == x && currentCoords.y == y){
    return;
  }

  currentCoords.x = x;
  currentCoords.y = y;
  mymap.setView([y - 300,x], 5);
  L.marker([y,x], {icon: myIcon}).addTo(mymap);
}
