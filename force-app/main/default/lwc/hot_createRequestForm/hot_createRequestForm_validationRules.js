
//element is the html-element to be validated
//validationRule is the function which calculates if the value is invalid, returns error message. "" if not trigger
export function runValidation(element, validationRules) {
	console.log("runValidation")
	console.log("element.value: ");
	console.log(element.value);
	for (let validationRule of validationRules) {
		console.log("checking")
		let errorMessage = validationRule(element.value);
		console.log("errorMessage: " + errorMessage)
		element.setCustomValidity(errorMessage);
		if (errorMessage != "") {
			console.log("Send Error")
			element.focus();
		}
		element.reportValidity();
	}
}

export function runValidationTest(input, validationRule) {
	for (let valRule of validationRule) {
		if (valRule(input) == "") {
			console.log("was true")
		}
		else {
			console.log("was false")
		}

	}
}

export function evaluate(input) {
	console.log(input + " != run");
	console.log(input != "run");
	return input != "run" ? "Ikke riktig ord" : "";
}
export function giveFalse(input) {
	console.log("givingFalse")
	console.log(input);
	return "";
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




