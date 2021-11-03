export function getParametersFromURL() {
    console.log('getParametersFromURL');
    let testURL = window.location.href;
    let params = testURL.split('?')[1];
    let parsed_params = null;
    if (params !== undefined) {
        parsed_params = parse_query_string(params);
    }
    return parsed_params;
}

function parse_query_string(query) {
    let vars = query.split('&');
    let query_string = {};
    for (let i = 0; i < vars.length; i++) {
        let pair = vars[i].split('=');
        let key = decodeURIComponent(pair[0]);
        let value = decodeURIComponent(pair[1]);
        // If first entry with this name
        if (typeof query_string[key] === 'undefined') {
            query_string[key] = decodeURIComponent(value);
            // If second entry with this name
        } else if (typeof query_string[key] === 'string') {
            let arr = [query_string[key], decodeURIComponent(value)];
            query_string[key] = arr;
            // If third or later entry with this name
        } else {
            query_string[key].push(decodeURIComponent(value));
        }
    }
    return query_string;
}
