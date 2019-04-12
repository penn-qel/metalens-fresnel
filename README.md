This is a simple suite in MATLAB for calculating the necessary parameters for a Metalens based on Fresnel phase profile and converting those parameters to a GDS file

## Required Software

-	**MATLAB**
-	**KLayout**
-	**S4** (if you choose to use the functions included in this suite to calculate pillar radii required for the phase profile)

## Scripts

-	**Metalens\_gen\_script.m**: calculate the necessary parameters for the discretized Fresnel phase profile and the dimensions needed for the subwavelength elements of the lens, then generate a GDS file using convert.rb
-	**convert.rb**: Ruby script for KLayout, gets called by Metalens\_gen\_script.m
