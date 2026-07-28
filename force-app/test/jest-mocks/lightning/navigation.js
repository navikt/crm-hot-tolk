export const Navigate = jest.fn();
export const GenerateUrl = jest.fn(() => Promise.resolve('https://www.example.com'));
export const CurrentPageReference = jest.fn();

const NavigateSymbol = Symbol('Navigate');
const GenerateUrlSymbol = Symbol('GenerateUrl');

export const NavigationMixin = (Base) => {
    return class extends Base {
        [NavigateSymbol](pageReference, replace) {
            Navigate(pageReference, replace);
        }

        [GenerateUrlSymbol](pageReference) {
            return GenerateUrl(pageReference);
        }
    };
};

NavigationMixin.Navigate = NavigateSymbol;
NavigationMixin.GenerateUrl = GenerateUrlSymbol;
