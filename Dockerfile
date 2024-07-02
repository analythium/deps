FROM rocker/r2u:24.04
RUN install.r remotes renv pak rconfig jsonlite yaml deps
RUN installGithub.r analythium/deps
RUN cp -p $(R RHOME)/site-library/deps/examples/03-cli/deps-cli.R /usr/local/bin/deps-cli
RUN chmod +x /usr/local/bin/deps-cli
CMD ["bash"]
