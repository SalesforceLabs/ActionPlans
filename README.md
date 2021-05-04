# Action Plans

## Table of Contents

-   [Direct deployment to an org](#direct-deployment-to-an-org): Quickest option to install this unmanaged code into your org

-   [Installing the app using a Scratch Org](#installing-the-app-using-a-scratch-org): This is the recommended installation option. Use this option if you are a developer who wants to experience the app and the code.

-   [Installing the app using a Developer Edition Org or a Trailhead Playground](#installing-the-app-using-a-developer-edition-org-or-a-trailhead-playground): Useful when tackling Trailhead Badges or if you want the app deployed to a more permanent environment than a Scratch org.

-   [Optional installation instructions](#optional-installation-instructions)

## Direct deployment to an org

<a href="https://githubsfdeploy.herokuapp.com?owner=SalesforceLabs&repo=ActionPlans&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Installing the app using a Scratch Org

1. Set up your environment. Follow the steps in the [Quick Start: Lightning Web Components](https://trailhead.salesforce.com/content/learn/projects/quick-start-lightning-web-components/) Trailhead project. The steps include:

    - Enable Dev Hub in your Trailhead Playground or Production org
    - Install Salesforce CLI
    - Install Visual Studio Code
    - Install the Visual Studio Code Salesforce extensions

1. If you haven't already done so, authorize your hub org and provide it with an alias (**myhuborg** in the command below):

    ```
    sfdx force:auth:web:login -d -a myhuborg
    ```

1. Clone the ActionPlans repository:

    ```
    git clone https://github.com/salesforcelabs/ActionPlans
    cd ActionPlans
    ```

1. Create a scratch org and provide it with an alias (**ActionPlans** in the command below):

    ```
    sfdx force:org:create -s -f config/project-scratch-def.json -a ActionPlans
    ```

1. Authenticate to your scratch org

	```
	sfdx force:auth:web:login -a ActionPlans
	```

1. Push the app to your scratch org:

    ```
    sfdx force:source:push
    ```

1. Assign the `Action_Plans_Admin` permission set to the admin user.

    ```
    sfdx force:user:permset:assign -n Action_Plans_Admin
    ```

1. Open the scratch org:

    ```
    sfdx force:org:open
    ```

1. In App Launcher, click **View All** then select the **Action Plans** app.

## Installing the App using a Sandbox with source tracking (Developer/Developer Pro Sanbox)

1. Set up your environment. Follow the steps in the [Quick Start: Lightning Web Components](https://trailhead.salesforce.com/content/learn/projects/quick-start-lightning-web-components/) Trailhead project. The steps include:

    - Enable Dev Hub in your Production org
    - Install Salesforce CLI
    - Install Visual Studio Code
    - Install the Visual Studio Code Salesforce extensions

1. In your Dev Hub org, in Setup > Dev Hub, enable "Enable Source Tracking in Developer and Developer Pro Sandboxes"

1. If you haven't already done so, authorize your hub org and provide it with an alias (**myhuborg** in the command below):

    ```
    sfdx force:auth:web:login -d -a myhuborg
    ```

1. Clone the ActionPlans repository:

    ```
    git clone https://github.com/salesforcelabs/ActionPlans
    cd ActionPlans
    ```

1. Update the project configuration file `sfdx-project.json` by adding to the My Domain login URL

	```
	"sfdcLoginUrl" : "https://test.salesforce.com"
	```

1. Authenticate to your sandbox
	```
	sfdx force:auth:web:login -a ActionPlans
	```

	or if you did not update `sfdx-project.json`
	```
	sfdx force:auth:web:login -r https://test.salesforce.com -a ActionPlans
	```

1. Push the app to your sandbox:

    ```
    sfdx force:source:push
    ```

1. Assign the `Action_Plans_Admin` permission set to the admin user.

    ```
    sfdx force:user:permset:assign -n Action_Plans_Admin
    ```

1. Open the sandbox:

    ```
    sfdx force:org:open
    ```

1. In App Launcher, click **View All** then select the **Action Plans** app.


## Installing the App using a Developer Edition Org or a Trailhead Playground

Follow this set of instructions if you want to deploy the app to a more permanent environment than a Scratch org.
This includes non source-tracked orgs such as a [free Developer Edition Org](https://developer.salesforce.com/signup) or a [Trailhead Playground](https://trailhead.salesforce.com/).

Start from a brand-new environment to avoid conflicts with previous work you may have done.

1. Authorize your Trailhead Playground or Developer org and provide it with an alias (**mydevorg** in the command below):

    ```
    sfdx force:auth:web:login -d -a mydevorg
    ```

1. Clone this repository:

    ```
    git clone https://github.com/salesforcelabs/ActionPlans
    cd ActionPlans
    ```

1. If you are setting up a Developer Edition: go to **Setup**, under **My Domain**, [register a My Domain](https://help.salesforce.com/articleView?id=domain_name_setup.htm&type=5).

1. Run this command to deploy the app.

    ```
    sfdx force:source:deploy -p force-app
    ```

1. If your org isn't already open, open it now:

    ```
    sfdx force:org:open -u mydevorg
    ```

1. Assign the `Action_Plans_Admin` permission set to the admin user.

    ```
    sfdx force:user:permset:assign -n Action_Plans_Admin
    ```

1. In App Launcher, select the **Action Plans** app.

## Optional Installation Instructions

This repository contains several files that are relevant if you want to add sample data, or integrate modern web development tooling to your Salesforce development processes or to your continuous integration/continuous deployment processes.

### Data Import

(Optional) This repository comes with sample data. To load sample Accounts and Contacts, run the following:
    ```
	sfdx force:data:tree:import -p ./data/data-plan.json
	```

This repository includes a sample Action Plan Template file, which you can import from the appropriate tab in the app. [Trade show follow-up](https://github.com/SalesforceLabs/ActionPlans/blob/main/data/Export%20-%20Trade%20Show%20follow%20up.xml). You may need to download the file from GitHub, or you can find it in your SFDX project in its folder.

### Code formatting

[Prettier](https://prettier.io/) is a code formatter used to ensure consistent formatting across your code base. To use Prettier with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) from the Visual Studio Code Marketplace. The [.prettierignore](/.prettierignore) and [.prettierrc](/.prettierrc) files are provided as part of this repository to control the behavior of the Prettier formatter.

### Code linting

[ESLint](https://eslint.org/) is a popular JavaScript linting tool used to identify stylistic errors and erroneous constructs. To use ESLint with Visual Studio Code, install [this extension](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode-lwc) from the Visual Studio Code Marketplace. The [.eslintignore](/.eslintignore) file is provided as part of this repository to exclude specific files from the linting process in the context of Lightning Web Components development.

### Pre-commit hook

This repository also comes with a [package.json](./package.json) file that makes it easy to set up a pre-commit hook that enforces code formatting and linting by running Prettier and ESLint every time you `git commit` changes.

To set up the formatting and linting pre-commit hook:

1. Install [Node.js](https://nodejs.org) if you haven't already done so
2. Run `npm install` in your project's root folder to install the ESLint and Prettier modules (Note: Mac users should verify that Xcode command line tools are installed before running this command.)

Prettier and ESLint will now run automatically every time you commit changes. The commit will fail if linting errors are detected. You can also run the formatting and linting from the command line using the following commands (check out [package.json](./package.json) for the full list):

```
npm run lint:lwc
npm run prettier
```
