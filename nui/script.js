document.addEventListener('DOMContentLoaded', () => {
    const stepsContainer = document.querySelector('.steps');
    const characterInputsChange = document.querySelector('.side-menu-container');
    const sideMenuLeft = document.querySelector(".side-menu-left");
    const sideMenuRight = document.querySelector(".side-menu-right");

    let isMouseHover = false
    let currentStep = 1;

    const contents = {
        'step-1': document.querySelector('.information-content'),
        'step-2': document.querySelector('.appearance-content'),
        'step-3': document.querySelector('.clothes-content')
    };

    // // FUNCTIONS // //

    const hideAllContents = () => {
        Object.values(contents).forEach(content => {
            content.style.display = 'none';
        });
    };

    const updateStep = (stepNumber, checkInputs) => {

        if (currentStep == 1){
            if (checkInputs){
                if (checkInputsData() == false){
                    return false;
                }
            }
        }

        const stepId = `step-${stepNumber}`;
        currentStep = stepNumber;
        showContent(stepId);
        updateNavigationButtons();
    };

    const updateNavigationButtons = () => {
        document.getElementById('previous').style.display = currentStep === 1 ? 'none' : 'inline-block';
        document.getElementById('next').style.display = currentStep === 3 ? 'none' : 'inline-block';
        document.getElementById('submit').style.display = currentStep === 3 ? 'inline-block' : 'none';
    };

    const showContent = stepId => {
        hideAllContents();

        if (stepId == 'step-2'){
            document.querySelector('.appearance-content-right').style.display = 'flex';
        } else {
            document.querySelector('.appearance-content-right').style.display = 'none';
        }

        contents[stepId].style.display = 'flex';

        stepsContainer.classList.remove('step-1', 'step-2', 'step-3');
        stepsContainer.classList.add(stepId);
    };

    function isValidDateAdvanced(dateString) {
        const parts = dateString.split("/");
        
        const day = parseInt(parts[0], 10);
        const month = parseInt(parts[1], 10);
        const year = parseInt(parts[2], 10);
     
        if (month < 1 || month > 12 || day < 1 || day > 31) {
            return false;
        }
     
        if ((month === 4 || month === 6 || month === 9 || month === 11) && day === 31) {
            return false;
        }
     
        if (month === 2) {
            const isLeap = (year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0));
            if (day > 29 || (day === 29 && !isLeap)) {
                return false;
            }
        }
     
        return true;
    }

    const checkInputsData = () => {
        const firstname = document.querySelector("#first-name").value;
        const lastname = document.querySelector("#last-name").value;

        const day = document.querySelector("#dob-day").value;
        const month = document.querySelector("#dob-month").value;
        const year = document.querySelector("#dob-year").value;
    
        const formattedDate = `${day}/${month}/${year}`;
    
        const sex = document.querySelector("input[type='radio'][name='sex']:checked");
        const height = document.querySelector("#height").value;

        if ((firstname.length < 4 || firstname.length > 20) || (lastname.length < 4 || lastname.length > 20)){
            return false;    
        } else if((day < 1 || month < 1 || year < 1900) || !isValidDateAdvanced(formattedDate)){
            return false;
        } else if(height < 140 || height > 210){ 
            return false;            
        } else if(sex == undefined){
            return false;
        }

        return true;
    }

    const mouseCheck = (state) => {
        isMouseHover = state

        fetch("https://fivem-character-creator-v2/mouseStatus", {
            method: "POST",
            body: JSON.stringify({
                status: state
            }),
        });

    }

    // // LISTENERS // //

    document.getElementById('previous').addEventListener('click', () => {
        if (currentStep > 1) {
            updateStep(currentStep - 1, true);
        }
    });

    document.getElementById('next').addEventListener('click', () => {
        if (currentStep < 3) {
            updateStep(currentStep + 1, true);
        }
    });

    document.getElementById('submit').addEventListener('click', () => {
        const firstnameVal = document.querySelector("#first-name").value;
        const lastnameVal = document.querySelector("#last-name").value;

        const day = document.querySelector("#dob-day").value;
        const month = document.querySelector("#dob-month").value;
        const year = document.querySelector("#dob-year").value;
    
        const formattedDate = `${day}/${month}/${year}`;
    
        const sexVal = document.querySelector("input[type='radio'][name='sex']:checked").value;
        const heightVal = document.querySelector("#height").value;

        fetch("http://fivem-character-creator-v2/register", {
            method: "POST",
            body: JSON.stringify({
                firstname: firstnameVal,
                lastname: lastnameVal,
                dateofbirth: formattedDate,
                sex: sexVal,
                height: heightVal,
            }),
        });
    });

    window.addEventListener("message", (event) => {
        if (event.data.type === "enableui") {
            if (event.data.enable == true){
                document.getElementsByTagName("BODY")[0].style.display = "block";
                const elements = JSON.parse(event.data.componentData)
                elements.forEach(element => {
                    const sliderVal = document.querySelector(`p[name="${element.name}"]`)
                    const inputEl = document.getElementById(element.name)

                    if (sliderVal != null){
                        sliderVal.innerText = `${element.value}/${element.max}`;
                    }

                    if (inputEl != null){
                        inputEl.setAttribute("value", element.value);
                        inputEl.setAttribute("max", element.max);
                        inputEl.setAttribute("min", element.min);
                    }
                });
            } else {
                document.getElementsByTagName("BODY")[0].style.display = "none";
            }
        }
    });  

    characterInputsChange.addEventListener('input', (e) => {
        
        fetch("https://fivem-character-creator-v2/updateCharValue", {
            method: "POST",
            body: JSON.stringify({
              name: e.target.id,
              value: e.target.value
            }),
        });
    });

    sideMenuLeft.addEventListener("mouseleave", () => mouseCheck(false));
    sideMenuLeft.addEventListener("mouseover", () =>  mouseCheck(true));

    sideMenuRight.addEventListener("mouseleave", () => mouseCheck(false));
    sideMenuRight.addEventListener("mouseover", () =>  mouseCheck(true));

    updateStep(1, false);
});

const inputs = document.querySelectorAll('input[type="text"], input[type="number"]');
const radios = document.querySelectorAll('input[type="radio"]');

const getLabelForInput = input => document.querySelector(`label[for="${input.id}"]`);

const toggleClass = input => {
    const label = getLabelForInput(input);
    if (label) {
        if (input.value.trim() !== "" || document.activeElement === input || input.checked) {
            label.classList.add('not-empty');
        } else {
            label.classList.remove('not-empty');
        }
    }
};

inputs.forEach(input => {
    input.addEventListener('input', () => toggleClass(input));
    input.addEventListener('focus', () => toggleClass(input));
    input.addEventListener('blur', () => toggleClass(input));
});
