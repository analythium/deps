FROM eddelbuettel/r2u:22.04
RUN install.r remotes renv pak rconfig jsonlite yaml
RUN installGithub.r analythium/deps
RUN cp /usr/local/lib/R/site-library/deps/examples/03-cli/deps-cli.R /usr/local/bin/deps-cli
RUN chmod +x /usr/local/bin/deps-cli
CMD ["bash"]
