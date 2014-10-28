#!/usr/bin/env R

## Tools for interactive genome binning in R

## Version 1 - 2014-10-28 - Converted previous version to object-oriented paradigm
## Contact: kbseah@mpi-bremen.de

## Required packages:
##  sp
##  plyr

## Required input files:
##  Output from pileup.sh tool (BBMap package) that was generated with a reference Fasta file (important!)

## Optional input files:
##  Marker genes with phylotypes assigned, generated by AMPHORA2 or Phyla-AMPHORA and parsed by my script
##  SSU genes detected by barrnap, output assigned taxonomy by my script
##  tRNA genes detected by tRNAscan-SE, output directly imported

########################################################################################################################
## Single plot tools:

#genomestats.create <- function (scaffold.stats, marker.list, ssu.list, trna.list) {
## Create an object of class "genomestats" -- called by genomestats.default
#    theresult <- list(scaff=scaffold.stats,mark=marker.list,ssu=ssu.list,trna=trna.list)
#}

# d <- genomestats("../1236Aa1re1.coverage","../phyla_amphora/phylotype.result.parsed","../barrnap/1236Aa1re1.ssu.tab","../1236Aa1re1.trna.out")

genomestats <- function (covstats,marker.list,ssu.list,trna.list) UseMethod ("genomestats")
genomestats.default <- function (covstats,marker.list=NA,ssu.list=NA,trna.list=NA) {            # Import files and combine them into an object of class "genomestats"
    scaff <- read.table(file=as.character(covstats),sep="\t",header=T)
    if ( !is.na(marker.list )) {                                                                   # If input marker file is not specified, make the field NA
        mark <- read.table(file=as.character(marker.list),sep="\t",header=T)
        Num_markers <- dim(mark)[1]
    } else {
        mark <- NA
        Num_markers <- NA
    }
    if ( !is.na(ssu.list) ) {
        ssu <- read.table(file=as.character(ssu.list),sep="\t",header=T)
        Num_SSU <- dim(ssu)[1]
    } else {
        ssu <- NA
        Num_SSU <- NA
    }
    if ( !is.na(trna.list)) {
        trna <- read.table(file=as.character(trna.list),sep="\t",skip=3,header=F)
        names(trna) <- c("scaffold","tRNA_no","tRNA_begin","tRNA_end","tRNA_type","Anticodon","Intron_begin","Intron_end","Cove_score")
        Num_tRNAs <- dim(trna)[1]
    } else {
        trna <- NA
        Num_tRNAs <- NA
    }
    summarystats <- data.frame(Total_length=sum(scaff$Length),Num_scaffolds=length(scaff$ID),Num_markers,Num_SSU,Num_tRNAs)
    theresult <- list(scaff=scaff,mark=mark,ssu=ssu,trna=trna,summary=summarystats)
    theresult$call <- match.call()
    class(theresult) <- "genomestats"
    theresult
}

print.genomestats <- function(x) {
    cat("Object of class genomestats\n\n")
    cat("Call:\n")
    print(x$call)
    cat ("\nSummary:\n")
    print(x$summary)
}

summary.genomestats <- function(x) {        # Identical to "print" behavior
    cat("Object of class genomestats\n\n")
    cat("Call:\n")
    print(x$call)
    cat ("\nSummary:\n")
    print(x$summary)
}

plot.genomestats <- function(x, cutoff=0, taxon="Class", assembly="",       # Basic inputs
                             marker=TRUE, ssu=FALSE, trna=FALSE, consensus=TRUE,legend=FALSE, textlabel=FALSE,  # Switches for various plot features
                             col="grey", log="y", main="default", xlab="GC",ylab="Coverage", ...) {
    if (cutoff > 0) {
        x$scaff <- subset(x$scaff,Length >= cutoff)
    }
    if (main=="default") {
        main=paste("Coverage vs. GC plot for metagenome ",as.character(assembly))
    }
    plot(x$scaff$Ref_GC,x$scaff$Avg_fold,pch=20,cex=sqrt(x$scaff$Length)/100, col=col, log=log, xlab=xlab, ylab=ylab, main=main, ...)
    if (marker && !is.na(x$mark)) {   # Add markers to plot if marker flag is TRUE and x$mark has been specified
        mark.stats <- generate.plot.colors(x$scaff, x$mark, taxon, consensus)
        points(mark.stats$Ref_GC,mark.stats$Avg_fold,pch=20,cex=sqrt(mark.stats$Length)/100,col=as.character(mark.stats$colors)) # Add points for scaffolds with marker genes, colored by their taxon
        if (legend) {       # If requested to add a legend to plot
            colorframe <- generate.legend.colors(x$scaff, x$mark, taxon, consensus)
            new.colorframe <- subset(colorframe,colors!="grey50")
            newrow <- c("singletons","grey50")
            new.colorframe <- rbind (new.colorframe,newrow)
            legend ("topright",legend=new.colorframe$taxon,cex=0.6,fill=as.character(new.colorframe$colors))
        }
    }
    if (ssu && !is.na(x$ssu)) {
        ssu.stats <- merge.scaff.marker(x$scaff, x$ssu, taxon, consensus=FALSE)
        points(ssu.stats$Ref_GC, ssu.stats$Avg_fold, pch=10, cex=2, col="black")
        if(textlabel==TRUE) {
            text(ssu.stats$Ref_GC,ssu.stats$Avg_fold,as.character(ssu.stats$taxon),pos=3,offset=0.2,font=2)
        }
    }
    if (trna && !is.na(x$trna)) {
        trna.stats <- merge(x$scaff,x$trna,by.x="ID",by.y="scaffold")
        points(trna.stats$Ref_GC,trna.stats$Avg_fold,pch=4,cex=1,col="black")
    }
}


choosebin.genomestats <- function(x,taxon="Class",num.points=6,draw.polygon=TRUE,save=FALSE,file="interactive_bin.list") {
## Wrapper for picking out bin on plot interactively and immediately reporting the statistics on scaffolds contained in the bin
    thebin <- pick.bin.points(num.points=num.points,draw.polygon=draw.polygon)
    require(sp)
    inpolygon <- point.in.polygon(x$scaff$Ref_GC,x$scaff$Avg_fold,thebin$x,thebin$y)
    x.subset <- x$scaff[which(inpolygon==1),]
    x.shortlist <- as.character(x.subset$ID)
    theresult <- genomestatsbin(shortlist=x.shortlist,x=x,taxon=taxon,points=thebin,save=save,file=file)
    return(theresult)
}

genomestatsbin <- function(shortlist,x,taxon,points,save,file) UseMethod ("genomestatsbin")
genomestatsbin.default <- function(shortlist,x,taxon,points=NA,save=FALSE,file="interactive_bin.list") {
## Get bin from genomestats object and a shortlist of scaffolds which should be in the bin
    scaff.subset <- subset(x$scaff,ID %in% shortlist)
    bin.nummarkers <- NA    # Initialize value of bin.nummarkers for summary, in case the marker.list is not supplied
    bin.uniqmarkers <- NA
    bin.numtRNAs <- NA      # Likewise for number of tRNAs
    bin.uniqtRNAs <- NA
    bin.numSSUs <- NA
    marker.tab <- NA
    marker.stats.subset <- NA
    tRNAs.tab <- NA
    trna.stats.subset <- NA
    if (!is.na(x$mark)) {
        marker.stats.subset <- subset(x$mark,scaffold %in% shortlist)
        bin.nummarkers <- dim(marker.stats.subset)[1]                                                                       # Total number of markers in the bin
        marker.tab <- table(marker.stats.subset$gene)                                                                       # Table of counts of each marker that is present (zeroes not shown)
        bin.uniqmarkers <- length(which(marker.tab > 0))                                                                    # Count total number of unique markers
        bin.singlemarkers <- length(which(marker.tab == 1))                                                                 # Count total number of single-copy markers
    }
    if (!is.na(x$ssu)) {
        ssu.stats.subset <- subset(x$ssu,scaffold %in% shortlist)
        bin.numSSUs <- dim(ssu.stats.subset)[1]     # Count total number of SSUs in the bin
    }
    if (!is.na(x$trna)) {
        trna.stats.subset <- subset(x$trna,scaffold %in% shortlist)
        bin.numtRNAs <- dim(trna.stats.subset)[1]
        tRNAs.tab <- table(trna.stats.subset$tRNA_type)
        bin.uniqtRNAs <- length(which(tRNAs.tab > 0))                                                                       # Count total number of unique tRNAs
    }
    bin.length <- sum(scaff.subset$Length)                                                                     # Total length of all scaffolds in the bin
    bin.numscaffolds <- dim(scaff.subset)[1]                                                                   # Total number of scaffolds in the bin
    bin.summary <- data.frame(Total_length=bin.length,Num_scaffolds=bin.numscaffolds,Num_markers=bin.nummarkers,Num_unique_markers=bin.uniqmarkers,Num_singlecopy_markers=bin.singlemarkers,
                              Num_SSUs=bin.numSSUs,Num_tRNAs=bin.numtRNAs,Num_tRNAs_types=bin.uniqtRNAs)
    if (save) {                                                                                                         # Option to export list of scaffolds contained in this bin, e.g. for reassembly
        write(as.vector(scaff.subset$ID),file=file)
    }
    result <- list(summary=bin.summary,marker.table=marker.tab,tRNA.table=tRNAs.tab,scaff=scaff.subset,mark=marker.stats.subset,
                   ssu=ssu.stats.subset,trna=trna.stats.subset,points=points)
    class(result) <- "genomestatsbin"
    return(result)
}

print.genomestatsbin <- function(x) {
    cat("Object of class genomestatsbin\n")
    cat ("\nSummary:\n")
    print(x$summary)
}

summary.genomestatsbin <- function(x) { # Identical to print method
    cat("Object of class genomestatsbin\n")
    cat ("\nSummary:\n")
    print(x$summary)
}

points.genomestatsbin <- function(x,col="black", ...) {     # points method is customized for overlay onto genomestats plot
    points(x$scaff$Ref_GC,x$scaff$Avg_fold,pch=20,cex=sqrt(as.numeric(x$scaff$Length))/100,col=col, ...)
}

plot.genomestatsbin <- function(x, ... ) {              # inherit the same plot method as genomestats class for simplicity
    plot.genomestats (x, ...)
}

fastg_fishing.genomestatsbin <- function(x,bin,fastg.file,taxon="Class",save=FALSE,file="fished_bin.list") {
# Given a genomestats object x and a genomestatsbin object bin and a Fastg file,
#  return a new genomestatsbin object comprising scaffolds with connectivity to the original bin
    command <- "perl"
    script.path <- "/home/kbseah/tools/my_scripts/genome-bin-tools/fastg_parser.pl"                             # Change this to the path to your copy of fastg_parser.pl
    command.params <- paste(script.path,"-i",fastg.file,"-o /tmp/tmp.fishing_output -b - -r")                   # By default throws away fastg_parser.pl output to /tmp/
    fished.contigs.list <- system2(command,command.params,input=as.character(bin$scaff$ID),stderr=NULL,stdout=TRUE)
    newbin <- genomestatsbin(fished.contigs.list,x,taxon=taxon,save=save,file=file)
    return(newbin)
}

merge.scaff.marker <- function(scaffold.stats,marker.list,taxon,consensus=TRUE) {
## Merge table of scaffold statistics (output from pileup.sh in BBMap package) and table of marker statistics parsed by parse_phylotype_result.pl
## This function needed by other functions in this file
    marker.list[,"taxon"] <- marker.list[,which(names(marker.list)==taxon)]
    marker.stats <- merge(scaffold.stats,marker.list,by.x="ID",by.y="scaffold")
    if (consensus) {    # For scaffolds with multiple marker genes, take majority consensus of marker taxon assignment
        require(plyr)
        #scaffs.with.multi <- as.vector(names(table(marker.stats$ID)[which(table(marker.stats$ID)>1)]))
        #consensus.list <- ddply(marker.list, .(scaffold), function(x) levels(x$taxon)[which.max(tabulate(x$taxon))])
        consensus.list <- ddply(marker.list, .(scaffold), summarize, taxon=levels(taxon)[which.max(tabulate(taxon))])
        marker.stats <- merge(scaffold.stats,consensus.list,by.x="ID",by.y="scaffold")
    }
    return(marker.stats)
}

generate.plot.colors <- function(scaffold.stats, marker.list, taxon, consensus) {           # This took a very long time to get it right
## Generates colors for marker gene phylotypes in plot
    marker.stats <- merge.scaff.marker(scaffold.stats,marker.list,taxon, consensus)          # Some table merging to have points to plot for the markers
    marker.list[,"taxon"] <- marker.list[,which(names(marker.list)==taxon)]
    singleton.taxa <- names(table(marker.list$taxon)[which(table(marker.list$taxon)==1)])       # Count how many taxa are only supported by one marker gene
    top.taxon <- names(table(marker.list$taxon)[which.max(table(marker.list$taxon))])           # Which taxon has the most marker genes?
        # Use which.max() because it breaks ties. Otherwise all genomes with same number of marker genes will have same color!
        # Important: Identification of singleton taxa uses the original marker.list because after "consensus",
        #  each scaffold has only one taxon assignment and scaffolds with >1 marker will be undercounted
    ### For plot colors - identify singleton taxa and the taxon with the highest marker counts, and assign them special colors
    taxnames <- names(table(marker.stats$taxon))                                                    # Names of taxa
    taxcolors <- rep("",length(names(table(marker.stats$taxon))))                                   # Create vector to hold color names
    taxcolors[which(names(table(marker.stats$taxon)) %in% singleton.taxa)] <- "grey50"              # Which taxa are singletons? Give them the color "grey50"
    numsingletons <- length(taxcolors[which(names(table(marker.stats$taxon)) %in% singleton.taxa)]) # Count how many singleton taxa
    taxcolors[which(names(table(marker.stats$taxon))==top.taxon)] <- "red"                          # Which taxon has the most marker genes? Give it the color "red"
    numcolors <- length(table(marker.stats$taxon)) - 1 - numsingletons                              # How many other colors do we need, given that all singletons have same color?
    thecolors <- rainbow(numcolors,start=1/6,end=5/6)                                               # Generate needed colors, from yellow to magenta, giving red a wide berth
    taxcolors[which(!(names(table(marker.stats$taxon)) %in% singleton.taxa)  & names(table(marker.stats$taxon))!=top.taxon)] <- thecolors
    colorframe <- data.frame(taxon=taxnames,colors=taxcolors)                                       # Data frame containing which colors correspond to which taxa
    marker.stats <- merge(marker.stats,colorframe,by="taxon")                                       # Merge this by taxon into the marker.stats table for plotting (this works even when consensus option is called)
    return(marker.stats)
}

generate.legend.colors <- function(scaffold.stats, marker.list,taxon, consensus) {
    marker.stats <- merge.scaff.marker(scaffold.stats,marker.list,taxon, consensus)          # Some table merging to have points to plot for the markers
    marker.list[,"taxon"] <- marker.list[,which(names(marker.list)==taxon)]
    singleton.taxa <- names(table(marker.list$taxon)[which(table(marker.list$taxon)==1)])       # Count how many taxa are only supported by one marker gene
    top.taxon <- names(table(marker.list$taxon)[which.max(table(marker.list$taxon))])           # Which taxon has the most marker genes?
    taxnames <- names(table(marker.stats$taxon))                                                    # Names of taxa
    taxcolors <- rep("",length(names(table(marker.stats$taxon))))                                   # Create vector to hold color names
    taxcolors[which(names(table(marker.stats$taxon)) %in% singleton.taxa)] <- "grey50"              # Which taxa are singletons? Give them the color "grey50"
    numsingletons <- length(taxcolors[which(names(table(marker.stats$taxon)) %in% singleton.taxa)]) # Count how many singleton taxa
    taxcolors[which(names(table(marker.stats$taxon))==top.taxon)] <- "red"                          # Which taxon has the most marker genes? Give it the color "red"
    numcolors <- length(table(marker.stats$taxon)) - 1 - numsingletons                              # How many other colors do we need, given that all singletons have same color?
    thecolors <- rainbow(numcolors,start=1/6,end=5/6)                                               # Generate needed colors, from yellow to magenta, giving red a wide berth
    taxcolors[which(!(names(table(marker.stats$taxon)) %in% singleton.taxa)  & names(table(marker.stats$taxon))!=top.taxon)] <- thecolors
    colorframe <- data.frame(taxon=taxnames,colors=taxcolors)                                       # Data frame containing which colors correspond to which taxa
    marker.stats <- merge(marker.stats,colorframe,by="taxon")                                       # Merge this by taxon into the marker.stats table for plotting (this works even when consensus option is called)
    return(colorframe)
}

pick.bin.points <- function(num.points=6,draw.polygon=TRUE) {
## Wrapper for locator() and polygon() to perform interactive binning on the current plot. Returns the polygon vertices which can be used in get.bin.stats()
    thepoints <- locator(num.points,pch=20,type="p")
    if (draw.polygon) { polygon(thepoints) }
    return(thepoints)
}

########################################################################################################################
## Differential coverage double plot tools:

diffcovstats <- function (covstats1,covstats2,marker.list,ssu.list,trna.list) UseMethod ("diffcovstats")
diffcovstats.default <- function (covstats1,covstats2,marker.list=NA,ssu.list=NA,trna.list=NA) {            # Import files and combine them into an object of class "diffcovstats"
    scaff1 <- read.table(file=as.character(covstats1),sep="\t",header=T)
    scaff2 <- read.table(file=as.character(covstats2),sep="\t",header=T)
    cov1 <- data.frame(ID=scaff1$ID,Avg_fold_1=scaff1$Avg_fold,Ref_GC=scaff1$Ref_GC,Length=scaff1$Length)    # Reformat and merge the coverage information from tables
    cov2 <- data.frame(ID=scaff2$ID,Avg_fold_2=scaff2$Avg_fold)
    diffcov <- merge(cov1,cov2,by="ID")
    if ( !is.na(marker.list) ) {                                                                   # If input marker file is not specified, make the field NA
        mark <- read.table(file=as.character(marker.list),sep="\t",header=T)
        Num_markers <- dim(mark)[1]
    } else {
        mark <- NA
        Num_markers <- NA
    }
    if ( !is.na(ssu.list) ) {
        ssu <- read.table(file=as.character(ssu.list),sep="\t",header=T)
        Num_SSU <- dim(ssu)[1]
    } else {
        ssu <- NA
        Num_SSU <- NA
    }
    if ( !is.na(trna.list) ) {
        trna <- read.table(file=as.character(trna.list),sep="\t",skip=3,header=F)
        names(trna) <- c("scaffold","tRNA_no","tRNA_begin","tRNA_end","tRNA_type","Anticodon","Intron_begin","Intron_end","Cove_score")
        Num_tRNAs <- dim(trna)[1]
    } else {
        trna <- NA
        Num_tRNAs <- NA
    }
    meancov1 <- sum(diffcov$Avg_fold_1*diffcov$Length)/sum(diffcov$Length)
    meancov2 <- sum(diffcov$Avg_fold_2*diffcov$Length)/sum(diffcov$Length)
    summarystats <- data.frame(Total_length=sum(diffcov$Length),Num_scaffolds=length(diffcov$ID),Mean_coverage_1=meancov1,Mean_coverage_2=meancov2,Num_markers,Num_SSU,Num_tRNAs)
    theresult <- list(diffcov=diffcov,mark=mark,ssu=ssu,trna=trna,summary=summarystats)
    theresult$call <- match.call()
    class(theresult) <- "diffcovstats"
    theresult
}

print.diffcovstats <- function(x) {
    cat("Object of class diffcovstats\n\n")
    cat("Call:\n")
    print(x$call)
    cat ("\nSummary:\n")
    print(x$summary)
}

summary.diffcovstats <- function(x) {        # Identical to "print" behavior
    cat("Object of class diffcovstats\n\n")
    cat("Call:\n")
    print(x$call)
    cat ("\nSummary:\n")
    print(x$summary)
}

plot.diffcovstats <- function(x, cutoff=0, taxon="Class", assembly="",       # Basic inputs
                             gc=FALSE, marker=TRUE, ssu=FALSE, trna=FALSE, consensus=TRUE,legend=FALSE, textlabel=FALSE,  # Switches for various plot features
                             col="grey", log="xy", xlab="Coverage, sample 1", ylab="Coverage, sample 2", ...) {
    if (cutoff > 0) {
        x$diffcov <- subset(x$diffcov,Length >= cutoff)
    }
    gbr <- colorRampPalette(c("green","blue","orange","red"))   # Define colors for GC palette -- from Albertsen script
    if (gc && !is.na(x$mark) && marker) {       # Plot both with GC colors and Marker colors
        cat ("Please choose to plot only with GC or marker coloring, not both.\n")
    }
    else if (gc && !marker) {                   # Plot only with GC colors
        palette(adjustcolor(gbr(70)))           # Apply palette
        plot(x$diffcov$Avg_fold_1,x$diffcov$Avg_fold_2,pch=20,cex=sqrt(x$diffcov$Length)/100, col=x$diffcov$Ref_GC*100,
             main=paste("Differential coverage colored by GC, metagenome ", as.character(assembly)), log=log, xlab=xlab, ylab=ylab,  ...) # Base plot
        if (legend) {   # Add color scale for GC
            legendcolors <- c("20","30","40","50","60","70")    # Values to show in legend
            legend("topright",legend=as.character(legendcolors),fill=as.numeric(legendcolors))
        }
    }
    else if (!gc && !is.na(x$mark) && marker) { # Plot only with Marker colors
        plot(x$diffcov$Avg_fold_1,x$diffcov$Avg_fold_2,pch=20,cex=sqrt(x$diffcov$Length)/100,
             main=paste("Differential coverage colored by markers, metagenome ", as.character(assembly)), col=col, log=log, xlab=xlab, ylab=ylab,  ...) # Base plot
        mark.stats <- generate.plot.colors(x$diffcov, x$mark, taxon, consensus)
        points(mark.stats$Avg_fold_1,mark.stats$Avg_fold_2,pch=20,cex=sqrt(mark.stats$Length)/100,col=as.character(mark.stats$colors)) # Add points for scaffolds with marker genes, colored by their taxon
        if (legend) {       # If requested to add a legend to plot
            colorframe <- generate.legend.colors(x$diffcov, x$mark, taxon, consensus)
            new.colorframe <- subset(colorframe,colors!="grey50")
            newrow <- c("singletons","grey50")
            new.colorframe <- rbind (new.colorframe,newrow)
            legend ("topright",legend=new.colorframe$taxon,cex=0.6,fill=as.character(new.colorframe$colors))
        }
    }
    else if (!gc && !marker) {                  # Plot uncolored
        plot(x$diffcov$Avg_fold_1,x$diffcov$Avg_fold_2,pch=20,cex=sqrt(x$diffcov$Length)/100,
             main=paste("Differential coverage plot, metagenome ", as.character(assembly)), col=col, log=log, xlab=xlab, ylab=ylab,  ...)
    }
    if (!(gc && marker)) {         # If only single plots generated, add SSU and tRNA overlay. If double plot generated, ignore.
        if (ssu && !is.na(x$ssu)) {
            ssu.stats <- merge.scaff.marker(x$diffcov, x$ssu, taxon, consensus=FALSE)
            points(ssu.stats$Avg_fold_1, ssu.stats$Avg_fold_2, pch=10, cex=2, col="black")
            if(textlabel==TRUE) {
                text(ssu.stats$Avg_fold_1,ssu.stats$Avg_fold_2,as.character(ssu.stats$taxon),pos=3,offset=0.2,font=2)
            }
        }
        if (trna && !is.na(x$trna)) {
            trna.stats <- merge(x$diffcov,x$trna,by.x="ID",by.y="scaffold")
            points(trna.stats$Avg_fold_1,trna.stats$Avg_fold_2,pch=4,cex=1,col="black")
        }
    }
}

choosebin.diffcovstats <- function(x,taxon="Class",num.points=6,draw.polygon=TRUE,save=FALSE,file="interactive_bin.list") {
## Wrapper for picking out bin on plot interactively and immediately reporting the statistics on scaffolds contained in the bin
    thebin <- pick.bin.points(num.points=num.points,draw.polygon=draw.polygon)
    require(sp)
    inpolygon <- point.in.polygon(x$diffcov$Avg_fold_1,x$diffcov$Avg_fold_2,thebin$x,thebin$y)
    x.subset <- x$diffcov[which(inpolygon==1),]
    x.shortlist <- as.character(x.subset$ID)
    theresult <- diffcovstatsbin(shortlist=x.shortlist,x=x,taxon=taxon,points=thebin,save=save,file=file)
    return(theresult)
}

diffcovstatsbin <- function(shortlist,x,taxon,points,save,file) UseMethod ("diffcovstatsbin")
diffcovstatsbin.default <- function(shortlist,x,taxon,points=NA,save=FALSE,file="interactive_bin.list") {
## Get bin from diffcovstats object and a shortlist of scaffolds which should be in the bin
    scaff.subset <- subset(x$diffcov,ID %in% shortlist)
    
    bin.nummarkers <- NA    # Initialize value of bin.nummarkers for summary, in case the marker.list is not supplied
    bin.uniqmarkers <- NA
    bin.numtRNAs <- NA      # Likewise for number of tRNAs
    bin.uniqtRNAs <- NA
    bin.numSSUs <- NA
    marker.tab <- NA
    marker.stats.subset <- NA
    tRNAs.tab <- NA
    trna.stats.subset <- NA
    if (!is.na(x$mark)) {
        marker.stats.subset <- subset(x$mark,scaffold %in% shortlist)
        bin.nummarkers <- dim(marker.stats.subset)[1]                                                                       # Total number of markers in the bin
        marker.tab <- table(marker.stats.subset$gene)                                                                       # Table of counts of each marker that is present (zeroes not shown)
        bin.uniqmarkers <- length(which(marker.tab > 0))                                                                    # Count total number of unique markers
        bin.singlemarkers <- length(which(marker.tab == 1))                                                                 # Count total number of single-copy markers
    }
    if (!is.na(x$ssu)) {
        ssu.stats.subset <- subset(x$ssu,scaffold %in% shortlist)
        bin.numSSUs <- dim(ssu.stats.subset)[1]     # Count total number of SSUs in the bin
    }
    if (!is.na(x$trna)) {
        trna.stats.subset <- subset(x$trna,scaffold %in% shortlist)
        bin.numtRNAs <- dim(trna.stats.subset)[1]
        tRNAs.tab <- table(trna.stats.subset$tRNA_type)
        bin.uniqtRNAs <- length(which(tRNAs.tab > 0))                                                                       # Count total number of unique tRNAs
    }
    bin.length <- sum(scaff.subset$Length)                                                                     # Total length of all scaffolds in the bin
    bin.numscaffolds <- dim(scaff.subset)[1]                                                                   # Total number of scaffolds in the bin
    meancov1 <- sum(scaff.subset$Avg_fold_1*scaff.subset$Length)/sum(scaff.subset$Length)
    meancov2 <- sum(scaff.subset$Avg_fold_2*scaff.subset$Length)/sum(scaff.subset$Length)
    bin.summary <- data.frame(Total_length=bin.length,Num_scaffolds=bin.numscaffolds,Mean_coverage_1=meancov1,Mean_coverage_2=meancov2,
                              Num_markers=bin.nummarkers,Num_unique_markers=bin.uniqmarkers,Num_singlecopy_markers=bin.singlemarkers,
                              Num_SSUs=bin.numSSUs,Num_tRNAs=bin.numtRNAs,Num_tRNAs_types=bin.uniqtRNAs)
    if (save) {                                                                                                         # Option to export list of scaffolds contained in this bin, e.g. for reassembly
        write(as.vector(scaff.subset$ID),file=file)
    }
    result <- list(summary=bin.summary,marker.table=marker.tab,tRNA.table=tRNAs.tab,diffcov=scaff.subset,mark=marker.stats.subset,
                   ssu=ssu.stats.subset,trna=trna.stats.subset,points=points)
    class(result) <- "diffcovstatsbin"
    return(result)
}

print.diffcovstatsbin <- function(x) {
    cat("Object of class diffcovstatsbin\n")
    cat ("\nSummary:\n")
    print(x$summary)
}

summary.diffcovstatsbin <- function(x) { # Identical to print method
    cat("Object of class diffcovstatsbin\n")
    cat ("\nSummary:\n")
    print(x$summary)
}

points.diffcovstatsbin <- function(x,col="black", ...) {     # points method is customized for overlay onto genomestats plot
    points(x$diffcov$Avg_fold_1,x$diffcov$Avg_fold_2,pch=20,cex=sqrt(as.numeric(x$diffcov$Length))/100,col=col, ...)
}

plot.diffcovstatsbin <- function(x, ... ) {              # inherit the same plot method as genomestats class for simplicity
    plot.diffcovstats (x, ...)
}

fastg_fishing.diffcovstatsbin <- function(x,bin,fastg.file,taxon="Class",save=FALSE,file="fished_bin.list") {
# Given a diffcovstats object x and a diffcovstatsbin object bin and a Fastg file,
#  return a new diffcovstatsbin object comprising scaffolds with connectivity to the original bin
    command <- "perl"
    script.path <- "/home/kbseah/tools/my_scripts/genome-bin-tools/fastg_parser.pl"                             # Change this to the path to your copy of fastg_parser.pl
    command.params <- paste(script.path,"-i",fastg.file,"-o /tmp/tmp.fishing_output -b - -r")                   # By default throws away fastg_parser.pl output to /tmp/
    fished.contigs.list <- system2(command,command.params,input=as.character(bin$diffcov$ID),stderr=NULL,stdout=TRUE)
    newbin <- diffcovstatsbin(fished.contigs.list,x,taxon=taxon,save=save,file=file)
    return(newbin)
}