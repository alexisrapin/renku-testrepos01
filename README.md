Using the DADA2 pipeline for sequence variant identification
============================================================

Here we provide a R Notebook template to generate a sequences variants table from FASTQ files generated by Paired-End Illumina sequencing.
For maximal reproducibility, we also provide a R project file and its associated packrat packages managment directory.

For an example of report generated from the R Notebook, see [example.nb.html](http://htmlpreview.github.io/?https://github.com/chuvpne/dada2-pipeline/blob/master/example.nb.html).

Note: Commands described in this documentation assume that you are using a Unix CLI.

## Resources

* Git clone URL: https://github.com/chuvpne/dada2-pipeline.git
* Documentation: https://github.com/chuvpne/dada2-pipeline
* DADA2: https://benjjneb.github.io/dada2
* illumina-utils: https://github.com/merenlab/illumina-utils
* docker image with pre-installed environment: https://hub.docker.com/r/chuvpne/pne-docker

## System requirements

The minimal requirements are listed below then further detailed in this section:

* **R 3.6.0:** https://www.r-project.org
* **R packrat package:** https://cran.r-project.org/web/packages/packrat
* **RStudio:** https://www.rstudio.com
* **GNU parallel:** https://www.gnu.org/software/parallel
* **illumina-utils:** https://github.com/merenlab/illumina-utils
* **git:** https://git-scm.com/

**Note that additional system requirements as well as dependencies may be necessary for the installation of some R packages.**

For maximal reproducibility and easy deployement across machines and platforms, you can open the R Notebook template using **RStudio server running on a docker container**. A suitable docker image satisfying all system requirements for using the provided R Notebook template is available at **https://hub.docker.com/r/chuvpne/pne-docker**. Instructions are further provided below in the <b>Working on docker</b> section.

#### R

The DADA2 pipeline comes as a R package. Make sure that R (3.6.0 or higher) is installed before starting.

#### R packrat package

R packages are managed using packrat. This ensures maximal reproducibility and portability of the analysis by using an encapsulated, version controlled, installation of R packages instead of any system-level R packages installation.

Make sure that the packrat R package is installed before starting:

```
# R
> install.packages("packrat")
```

#### RStudio

The `dada2-pipeline.Rmd` file provided in this repository is a R Notebook. As such, it includes both code lines (chunks) and text and can be exported into html and pdf files.

The prefered way of using the `dada2-pipeline.Rmd` file is with the RStudio Integrated Development Environment (IDE). Make sure you have RStudio installed before starting.

#### GNU parallel

GNU parallel is a shell tool to execute jobs in parallel. Some chunks in the `dada2-pipeline.Rmd` R Notebook are written in bash and use GNU parallel to run commands in parallel and reduce computation time.
Make sure you have GNU parallel installed before starting.

On debian linux, you can install GNU parallel using the `apt-get` package manager command:
```
$ apt-get install parallel
```

You can find the documentation on GNU parallel [here](https://www.gnu.org/software/parallel). There is also an intro video available [here](https://www.youtube.com/playlist?list=PL284C9FF2488BC6D1) and examples [there](https://www.gnu.org/software/parallel/man.html#EXAMPLE:-Working-as-xargs--n1.-Argument-appending).

If needed, use the `man` command:
```
$ man parallel
```

#### illumina-utils

Illumina-utils is a small FASTQ files-processing library.
Some chunks in the `dada2-pipeline.Rmd` R Notebook use it to demultiplex FASTQ files.

Make sure illumina-utils is installed before starting. Installation instructions are available at https://github.com/merenlab/illumina-utils/.

Best is to create a virtual environment for illumina-utils using [virtualenv](https://virtualenv.pypa.io/en/latest/). On debian linux, you can install it using Python package manager `pip` command:
```
$ pip install virtualenv
$ virtualenv -p python3 ~/illumina-utils # important to specify Python3
$ source ~/illumina-utils/bin/activate
$ pip install illumina-utils
```

To activate/deactivate your illumina-utils virtual environment run:
```
$ source ~/illumina-utils/bin/activate
$ deactivate
```

#### git

This repository is managed using the git distributed version control system. You can get a local copy of it using the `git clone` command.
If not done yet, install git.

On debian linux, you can install git using the `apt-get` package manager command:
```
$ apt-get install git
```

## Files

Before starting, make sure you have the five files listed below:

1. **`R1.fastq.gz`**: FASTQ file for the forward read
2. **`R2.fastq.gz`**: FASTQ file for the reverse read
3. **`Index.fastq.gz`**: FASTQ file for the index read
4. **`barcode_to_sample.txt`**: A text file mapping index barcodes to samples
5. A DADA2-formatted reference database: see https://benjjneb.github.io/dada2/training.html. Per example, Silva version 132: `silva_nr_v132_train_set.fa.gz` and `silva_species_assignment_v132.fa.gz`. 

It is assumed that the FASTQ files were archived using gzip.

Please pay particular attention to the format of the files. The following points are critical:

* FASTQ files must use the Phred+33 quality score format and sequences headers (`@` lines) must fit the standard format of the CASAVA 1.8 output:

```
@EAS139:136:FC706VJ:2:2104:15343:197393 1:N:0:0
```

* The `barcode_to_sample.txt` file must contain two tab-delimited columns: the first for samples names and the second for samples barcodes as shown <a href="https://github.com/merenlab/illumina-utils/blob/master/examples/demultiplexing/barcode_to_sample.txt" target="_blank">here</a>. Avoid special characters.

If multiple sequencing runs have to be analyzed together, create a directory for each run and place the respective FASTQ and `barcode_to_sample_[runNN].txt` files inside. 

## Preparation

Get a copy of this repository and set it as your working directory:
```
$ git clone https://github.com/chuvpne/dada2-pipeline.git my_project_dir
$ cd my_project_dir
```


If not done yet, get a copy of the DADA2-formatted reference database of your choice at https://benjjneb.github.io/dada2/training.html. We recommend to store it in a directory dedicated to databases instead of keeping it inside the main project directory.
Per example, create a `db` directory in your home directory and download the SILVA version 132 reference database into it (Assuming wget is installed):
```
$ mkdir $HOME/db
$ wget https://zenodo.org/record/1172783/files/silva_nr_v132_train_set.fa.gz -P $HOME/db/
$ wget https://zenodo.org/record/1172783/files/silva_species_assignment_v132.fa.gz -P $HOME/db/
```


Place your FASTQ files and the `barcode_to_sample.txt` file in a directory, then place this directory within the directory named `run_data`.
The final directory structure should look like:
<pre>
my_project_dir
├── run_data
|   └── <b>run01</b>
|       ├── <b>R1.fastq.gz</b>
|       ├── <b>R2.fastq.gz</b>
|       ├── <b>Index.fastq.gz</b>
|       └── <b>barcode_to_sample.txt</b>
├── packrat
|   └── ...
├── dada2-pipeline.Rmd
├── dada2-pipeline.Rproj
├── LICENSE.txt
└── README.md
</pre>

If multiple sequencing runs have to be analyzed together, place each run directory inside the directory named `run_data`.
In this case, the final directory structure should look like:
<pre>
my_project_dir
├── run_data
|   ├── <b>run01</b>
|   |   ├── <b>R1.fastq.gz</b>
|   |   ├── <b>R2.fastq.gz</b>
|   |   ├── <b>Index.fastq.gz</b>
|   |   └── <b>barcode_to_sample.txt</b>
|   ├── <b>run02</b>
|   |   ├── <b>R1.fastq.gz</b>
|   |   ├── <b>R2.fastq.gz</b>
|   |   ├── <b>Index.fastq.gz</b>
|   |   └── <b>barcode_to_sample.txt</b>
.   .
.   .
.   .
|   └── <b>runNN</b>
|       ├── <b>R1.fastq.gz</b>
|       ├── <b>R2.fastq.gz</b>
|       ├── <b>Index.fastq.gz</b>
|       └── <b>barcode_to_sample.txt</b>
├── packrat
|   └── ...
├── dada2-pipeline.Rmd
├── dada2-pipeline.Rproj
├── LICENSE.txt
└── README.md
</pre>

## Usage

1. Load the `dada2-pipeline.Rproj` R project file in RStudio.

2. Open the `dada2-pipeline.Rmd` R Notebook template in RStudio and follow the instructions in the text and comments. At the end of the pipeline, inital files and results are archived into two separate archives. 

3. Store archives in a safe place!

## Working on docker

A docker image satisfying all system requirements for using the provided R Notebook template is available at https://hub.docker.com/r/chuvpne/pne-docker.
See https://github.com/chuvpne/pne-docker for the documentation.
This docker image comes with pre-installed R, RStudio server and illumina-utils. The R packrat package is also pre-installed and all system requirements for the installation and usage of the R dada2 package are met.

The DADA2-formatted reference database must be mounted on the docker container.
To do that, add the following option to the `docker run` command documented at https://github.com/chuvpne/pne-docker:

`-v /path/to/train_set.fa.gz/directory:/home/$USER/db:ro`

Replace `/path/to/train_set.fa.gz/directory` by the right path to the directory containing the reference database. Per example: `$HOME/db/silva`.

## Citation

If you used this repository in a publication, please mention its url.
Per example:

**_The implementation of the DADA2 pipeline used to process FASTQ files is available at https://github.com/chuvpne/dada2-pipeline._**


In addition, you may cite the tools used by this pipeline:

* **DADA2:** Callahan BJ, McMurdie PJ, Rosen MJ, Han AW, Johnson AJA, Holmes SP
(2016). "DADA2: High-resolution sample inference from Illumina amplicon
data." _Nature Methods_, *13*, 581-583. doi: 10.1038/nmeth.3869.

* **illumina-utils:** Eren AM, Vineis JH, Morrison HG, Sogin ML (2013). "A Filtering Method to Generate High Quality Short Reads Using Illumina Paired-End Technology." _PLOS ONE_, 8(6). doi: 10.1371/journal.pone.0066643.

## Rights

* Copyright (c) 2018 Service de Pneumologie, Centre Hospitalier Universitaire Vaudois (CHUV), Switzerland and Monash University, Melbourne, Australia
* License: The R Notebook template (.Rmd) is provided under the MIT license (See LICENSE.txt for details)
* Authors: A. Rapin, C. Pattaroni, B.J. Marsland

## Contributing

Thank you for your interest in contributing. Get started [here](https://github.com/chuvpne/dada2-pipeline/blob/master/CONTRIBUTING.md).
