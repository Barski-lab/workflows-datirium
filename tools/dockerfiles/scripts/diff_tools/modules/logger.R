import("futile.logger", attach=FALSE)

export(
    "setup",
    "info"
)


setup <- function(location, name="hlog", header=NULL, level=futile.logger::INFO, format="~m"){
    base::file.create(location)                                      # to start with an empty file
    futile.logger::flog.logger(
        name,
        level,
        appender=futile.logger::appender.file(location),
        layout=futile.logger::layout.format(format)
    )
    if (!is.null(header)){
        futile.logger:::.log_level(
            header, level=level, name=name,
            capture=FALSE, logger=NULL
        )
    }
}

info <- function(message, name="hlog", skip_stdout=FALSE){
    futile.logger::flog.info(message, name=name) 
    if (!skip_stdout) {print(message)}
}