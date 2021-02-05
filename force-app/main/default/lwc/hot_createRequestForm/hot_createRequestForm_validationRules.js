
//element is the html-element to be validated
//validationRule is the function which calculates if the value is invalid, returns true if errorMessage should be shown
//errorMessage is the message to be shown
export function runValidation(element, validationRule, errorMessage) {
	let condition = false;//validationRule(element.detail.value);
	if (condition) {
		element.setCustomValidity(errorMessage);
		element.focus();
	} else {
		element.setCustomValidity("");
	}
	element.reportValidity();
}

export function runValidationTest(input, validationRule) {
	if (validationRule(input)) {
		console.log("was true")
	}
	else {
		console.log("was false")
	}
}

export function evaluate(input) {
	console.log(input + " == run");
	console.log(input == "run");
	return input == run;
}

export function test_date(output, fun) {
	console.log(output)
	console.log(fun)
}

export function no() {
	return "no from function";
}
export function yes() {
	return "yes from function";
}


function date_inPast(date) {
	return new Date(date).getTime() < new Date().now()
}
function date_blank(date) {
	return date == "" || date == null;
}




