/**
 * Created by sunli on 17/5/29.
 */
var xmlns = "http://www.w3.org/2000/svg";

function createRecNode(id, x, y, width, height, fill_color, opacity) {
    var node = document.createElementNS(xmlns, "rect");
    node.setAttributeNS(null, "id", id);

    node.setAttributeNS(null, "width", width.toString());
    node.setAttributeNS(null, "height", height.toString());
    node.setAttributeNS(null, "opacity", opacity.toString());
    node.setAttributeNS(null, "x", x.toString());
    node.setAttributeNS(null, "y", y.toString());
    var styleAttr = document.createAttribute("style");
    styleAttr.nodeValue = "fill:" + fill_color;
    node.setAttributeNode(styleAttr);
    return node;
}

function createPolyLine(id, points_array, thick, color) {
    var node = document.createElementNS(xmlns, "polyline");
    node.setAttributeNS(null, "id", id);
    node.setAttributeNS(null, "points", points_array);
    var styleAttr = document.createAttribute("style");
    styleAttr.nodeValue = "fill:white; stroke:" + color + "; stroke-width:" + thick;
    node.setAttributeNode(styleAttr);
    return node;
}

function createLine(id, x1, y1, x2, y2, thick, color) {
    var node = document.createElementNS(xmlns, "line");
    node.setAttributeNS(null, "id", id);
    node.setAttributeNS(null, "x1", x1);
    node.setAttributeNS(null, "y1", y1);
    node.setAttributeNS(null, "x2", x2);
    node.setAttributeNS(null, "y2", y2);
    var styleAttr = document.createAttribute("style");
    styleAttr.nodeValue = "stroke:" + color + "; stroke-width:" + thick;
    node.setAttributeNode(styleAttr);
    return node;
}

function createLine(id, x1, y1, x2, y2, thick, color, dash_array) {
    var node = document.createElementNS(xmlns, "line");
    node.setAttributeNS(null, "id", id);
    node.setAttributeNS(null, "x1", x1);
    node.setAttributeNS(null, "y1", y1);
    node.setAttributeNS(null, "x2", x2);
    node.setAttributeNS(null, "y2", y2);
    var styleAttr = document.createAttribute("style");
    styleAttr.nodeValue = "stroke:" + color + "; stroke-width:" + thick + "; stroke-dasharray:" + dash_array;
    node.setAttributeNode(styleAttr);
    return node;
}

function createTextBox(id, x, y, text, font_size, color) {
    var node = document.createElementNS(xmlns, "text");
    node.setAttributeNS(null, "id", id);
    node.setAttributeNS(null, "x", x.toString());
    node.setAttributeNS(null, "y", y.toString());
    var styleAttr = document.createAttribute("style");
    styleAttr.nodeValue = "font-size:" + font_size + ";fill:" + color;
    node.setAttributeNode(styleAttr);
    node.textContent = text;
    return node;
}

var gold_line_max_idx = -1;
var gold_line_min_idx = -1;
var gold_line_max_price = 0;
var gold_line_min_price = 0;
var gold_line_current_high_light_position = "";
var gold_line_current_idx = 0;
var gold_line_another_idx = -1;
function draw_gold_line(evt) {
    if (gold_line_max_idx == -1 && gold_line_min_idx == -1) {
        gold_line_current_idx = get_item_index(evt.clientX);
        var temp_price = get_price(evt.clientY);
        var temp_gold_line_max_price = parseFloat(stock_data.items[gold_line_current_idx].item_highest_price);
        var temp_gold_line_min_price = parseFloat(stock_data.items[gold_line_current_idx].item_lowest_price);
        if (Math.abs(temp_gold_line_max_price - temp_price) > Math.abs(temp_price - temp_gold_line_min_price)) {
            show_high_light_point_1(gold_line_current_idx, temp_gold_line_min_price);
            gold_line_current_high_light_position = "min";
        }
        else {
            show_high_light_point_1(gold_line_current_idx, temp_gold_line_max_price);
            gold_line_current_high_light_position = "max";
        }
    }
    else{
        var current_price = get_price(evt.clientY);
        var current_idx = get_item_index(evt.clientX);
        if (gold_line_max_idx > -1) {
            if (current_price < gold_line_max_price){
                display_gold_line(-1, gold_line_max_idx, evt);
                if (Math.abs(get_y_value(stock_data.items[current_idx].item_highest_price) - evt.clientY) < 100
                    && stock_data.items[current_idx].item_lowest_price < gold_line_max_price) {
                    show_high_light_point_2(current_idx, stock_data.items[current_idx].item_lowest_price);
                    gold_line_another_idx = current_idx;
                }
                else{
                    hide_high_light_point_2();
                }
            }
        }
        if (gold_line_min_idx > -1) {
            if (current_price > gold_line_min_price){
                display_gold_line(gold_line_min_idx, -1, evt);
                if (Math.abs(get_y_value(stock_data.items[current_idx].item_highest_price) - evt.clientY) < 100
                    && stock_data.items[current_idx].item_highest_price > gold_line_min_price) {
                    show_high_light_point_2(current_idx, stock_data.items[current_idx].item_highest_price);
                    gold_line_another_idx = current_idx;
                }
                else {
                    hide_high_light_point_2();
                }
            }
        }
    }
}
function display_gold_line(min_idx, max_idx, evt) {
    hide_gold_line();
    var max_price = 0;
    var min_price = 0;
    if (min_idx == -1) {
        max_price = stock_data.items[max_idx].item_highest_price;
        min_price = get_price(evt.clientY);
    }
    if (max_idx == -1) {
        min_price = stock_data.items[min_idx].item_lowest_price;
        max_price = get_price(evt.clientY);
    }
    display_gold_line_between_prices(min_price, max_price);
}
/*
function display_gold_line(min_idx, max_idx) {
    hide_gold_line();
}
*/
function display_gold_line_between_prices(min_price, max_price) {
    if (min_price < max_price) {
        var f3_price = max_price - 0.382*(max_price - min_price);
        var f5_price = max_price - 0.618*(max_price - min_price);
        var max_line = createLine("gold_line_max", 0, get_y_value(max_price), k_line_map_x + k_line_map_width, get_y_value(max_price),
            "1", "yellow");
        svg.appendChild(max_line);
        var f3_line = createLine("gold_line_f3", 0, get_y_value(f3_price), k_line_map_x + k_line_map_width, get_y_value(f3_price),
            "1", "yellow", "2,2");
        svg.appendChild(f3_line);
        var f3_txt = createTextBox("f3_txt", k_line_map_x + k_line_map_width - 50, get_y_value(f3_price)-10,
            "f3:" + (Math.round(f3_price*100)/100).toString(), "15", "orange");
        svg.appendChild(f3_txt);
        var f5_line = createLine("gold_line_f5", 0, get_y_value(f5_price), k_line_map_x + k_line_map_width, get_y_value(f5_price),
            "1", "yellow", "2,2");
        svg.appendChild(f5_line);
        var min_line = createLine("gold_line_min", 0, get_y_value(min_price), k_line_map_x + k_line_map_width, get_y_value(min_price),
            "1", "yellow");
        svg.appendChild(min_line);
    }
}
function hide_gold_line() {
    var max_line = document.getElementById("gold_line_max");
    var f3_line = document.getElementById("gold_line_f3");
    var f3_txt = document.getElementById("f3_txt");

    var f5_line = document.getElementById("gold_line_f5");
    var min_line = document.getElementById("gold_line_min");
    if (max_line != null){
        svg.removeChild(max_line);
    }
    if(min_line != null) {
        svg.removeChild(min_line);
    }
    if (f3_line != null) {
        svg.removeChild(f3_line);
    }
    if (f3_txt != null) {
        svg.removeChild(f3_txt);
    }
    if (f5_line) {
        svg.removeChild(f5_line);
    }
}
function show_high_light_point_1(idx, price) {
    hide_high_light_point_1();
    var x = get_x_value(idx);
    var y = get_y_value(price);
    var high_light_point = createLine("high_light_point_1", x, y - 2 , x , y+2, 5, "blue");
    svg.appendChild(high_light_point);
}

function hide_high_light_point_1() {
    var high_light_point = document.getElementById("high_light_point_1");
    if (high_light_point!=null) {
        svg.removeChild(high_light_point);
    }
}

function show_high_light_point_2(idx, price) {
    hide_high_light_point_2();
    var x = get_x_value(idx);
    var y = get_y_value(price);
    var high_light_point = createLine("high_light_point_2", x, y - 2 , x , y+2, 5, "blue");
    svg.appendChild(high_light_point);
}

function hide_high_light_point_2() {
    gold_line_another_idx = -1;
    var high_light_point = document.getElementById("high_light_point_2");
    if (high_light_point!=null) {
        svg.removeChild(high_light_point);
    }
}
function show_price_date(evt) {
    var mouse_x = evt.clientX;
    var mouse_y = evt.clientY-10;
    var price_box = document.getElementById("price_box");
    var date_box = document.getElementById("date_box");
    if (price_box != null) {
        svg.removeChild(price_box);
    }
    price_box = createTextBox("price_box", svg_width - 30 , mouse_y, get_price(mouse_y), 13, "rgb(0,0,255)");
    svg.appendChild(price_box);

    if (date_box != null) {
        svg.removeChild(date_box);
    }
    date_box = createTextBox("date_box", mouse_x , svg_height, stock_data.items[get_item_index(mouse_x)].item_start_time.toString().split(' ')[0], 13, "rgb(0,0,255)");
    svg.appendChild(date_box);
}
function hide_price_date(evt) {
    var price_box = document.getElementById("price_box");
    var date_box = document.getElementById("date_box");
    if (price_box!=null)
        price_box.style.display = "none";
    if (date_box!=null)
        date_box.style.display = "none";
}