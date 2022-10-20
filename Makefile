#################################################################################
# Copyright (C) Robert Bosch GmbH. All Rights Reserved. Confidential.           #
#                                                                               #
# Distribution only to people who need to know this information in              #
# order to do their job.(Need-to-know principle).                               #
# Distribution to persons outside the company, only if these persons            #
# signed a non-disclosure agreement.                                            #
# Electronic transmission, e.g. via electronic mail, must be made in            #
# encrypted form.                                                               #
#                                                                               #
#                                                                               #
# Generic makefile for building the unit test and generating the reports        #
#                                                                               #
#################################################################################
#
#################################################################################
# sorted alphabetically
.PHONY: \
	clean \
	htmldocs
	
htmldocs:
	cd doc_project && make html
	
clean:
	cd doc_project && make clean
	
public_doc:
	 cp -rf doc_project/build/html/* docs