/**
 * Created by sunli on 17/5/30.
 */
function get_max_price(stock_data, start_index, end_index) {
    var max_price = 0;
    for(var i = start_index; i < stock_data.length && i <= end_index; i++ ) {
        if (i==start_index) {
            max_price = parseFloat(stock_data[i].item_highest_price);
        }
        else {
            max_price = Math.max(max_price, parseFloat(stock_data[i].item_highest_price));
        }
    }
    return max_price;
}

function get_min_price(stock_data, start_index, end_index) {
    var min_price = 0;
    for(var i = start_index; i < stock_data.length && i <= end_index ; i++ ) {
        if (i==start_index) {
            min_price = parseFloat(stock_data[i].item_lowest_price);
        }
        else {
            min_price = Math.min(min_price, parseFloat(stock_data[i].item_lowest_price));
        }
    }
    return min_price;
}

function get_item_date(date_time) {
    return date_time.split(' ')[0];
}