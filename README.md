# reMarkable tablet sync and page OCR
A quick hack for syncing notebooks off the reMarkable, converting them to PDF form, and running OCR on the pages. Attempts to only convert changed pages. Uses AWS textract for OCR. Can sync from cloud using [RemarkableAPI][5] or directly with SSH-over-USB. Only syncs one-way: down.

Loosely tested with a reMarkable2 on Linux and OSX(intel).

I admit this is not entirely end-user-friendly. If you know your way around a Unix shell, you should be ok.

I wrote this in a couple of evenings and don't have the time to support it properly. If you like it, help me make it better.

# Requirements
* `[brew/apt/dnf] install imagemagick jq awscli composer`
* `pip install boto3 pypdf2`
* [rm2pdf][1] built and installed in your path
* [RemarkableAPI][5] and see below

[5]: https://github.com/splitbrain/ReMarkableAPI "RemarkableAPI @ github"

[1]: https://github.com/rorycl/rm2pdf.git "rm2pdf @ github"

# Setup
## AWS Textract Handwriting Recognition
`aws configure` [this may help][2] (also look at [pricing][4] for OCR)

## For Web API sync
* clone [RemarkableAPI][5]
* copy the folder `src`, and the files `composer.json` and `remarkable.php` into this folder.
* run `composer install` and maybe look at the [instructions][5]. You need to authorize RemarkableAPI to interact with your reMarkable account.

## For SSH-over-USB sync
[Set up passwordless ssh and rsync on your tablet][3]

Example `.ssh/config` section:
    ```
    Host remarkable
    User root
    ControlMaster no
    ControlPath none
    Hostname 10.11.99.1
    ```

## Notebook UUIDs
Each reMarkable notebook is identified by a hexadecimal UUID. You need to find the UUIDs of the notebooks you want synced and add them to `notebooks.conf`

*  `ssh remarkable`
*  `ln -s ~/.local/share/remarkable/xochitl ~/content` <- for convenience
*  `cd content`
*  `grep [notebook_name] *.metadata|cut -f1 -d '.'` <- start here, then look at the metadata file to confirm

Back on the mainland, add the notebook hashes to `notebooks.conf`, one per line, like so:
    ```
    abcdef28-b5f0-4866-a35a-1257d7abcdef
    abcdef78-76e5-4236-a3db-5140ecabcdef
    ```

## Optional
Check the config variables at top of `rmocrsync.sh`

[2]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config "AWS CLI Setup"

[3]: https://github.com/lucasrla/remarkable-utils "Remarkable Utils"

[4]: https://aws.amazon.com/textract/pricing/ "AWS Textract Pricing"

# Usage
From the repo folder, update the notebook list per the above instructions and try running `./rmocrsync.sh ssh` or `./rmocrsync.sh web`. It _should_ work out of the box. 

If it completes successfully, take a look in the `notebooks` folder. You should have a folder of OCR text files (one file per page), and an annotated PDF that embeds the text in each page. 

# Demo (of an older version)
![OCR text](_assets/demo.gif)
## OCR Example
![OCR text](_assets/ocr.png)