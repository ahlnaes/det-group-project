
# Tombaugh Regio - DET Group 11 Project
<img width="225.5" height="637" alt="Tombaugh Regio Poster" src="https://github.com/user-attachments/assets/4df518c6-24dc-4875-acca-68bf53ff0b2e" />

## Introduction

**Tombaugh Regio** is an immersive virtual‑reality experience where sound and visuals merge into a single interactive environment. The project invites users to explore original music through dynamic 3D elements, transforming listening into a spatial and sensory journey.

Traditional music experiences are mostly passive and listeners have limited ways to engage with sound beyond hearing it. We wanted to challenge that limitation by exploring how music could be experienced rather than simply consumed.
 
By combining 3D modelling, Unity development, tangible interactions, music composition, visual design and effects, we created a virtual environment that visually interprets sound in real time. Users can move, interact, and respond to the music in a way that feels alive and personal.

Tombaugh Regio demonstrates how VR can expand the boundaries of musical expression. It offers artists new ways to present their work, gives audiences a deeper emotional connection to sound, and showcases the potential of immersive media as a creative tool.

## Design Process

The design of Tombaugh Regio was driven by a curiosity to explore new ways of experiencing music through immersive and interactive technology. Our process combined creative exploration with user-centered design. We moved iteratively between ideation, fast-prototyping, and testing - most of this documented in Figma. 

Access to the project's Figma board: <https://www.figma.com/board/VNWhUzGgp5skbM0sbQ9xRB/Project-Workspace?node-id=514-1382&t=VEsPPACkVEhxa9ll-1>

**Brainstorming** 
<img width="6817" height="5958" alt="image" src="https://github.com/user-attachments/assets/7182a5b5-29c6-4894-92ad-45e19ce1539c" />

**User Research/Persona** 
<img width="5240" height="2120" alt="image" src="https://github.com/user-attachments/assets/71108151-ec7c-40ed-ae3c-30a9cc6d73ec" />

**User Journey** 
<img width="2912" height="1824" alt="image" src="https://github.com/user-attachments/assets/b5f0aab1-8c20-4a4d-aec9-34762cb3db67" />


**Wireframes and Prototypes** 
<img width="9824" height="6624" alt="image" src="https://github.com/user-attachments/assets/76503f5f-3667-4a4f-811a-4d33dda66f08" />



## System description

### Features

- Immersive sphere room environment with a fully enclosed spatial experience
- Detailed 3D models, including a pedestal and a globe representing Pluto
- Interactive hand-tracking controls for natural interaction with objects
- Accessible and user-friendly design, suitable for a wide range of users
- Real-time audioreactive shader system driven by a custom DSP audio analysis system
- Compatible with XR headsets, including devices like the Meta Quest 3

Watch the demo video or try the live version.

Link: <https://extralitylab.dsv.su.se/project/det/>

## Installation

To install and run **Tombaugh Regio** on your platform or device, follow the instructions below:

| Platform | Device     | Requirements                        |     |
| ----------| ------------| -------------------------------------| -----|
| Android  | Meta Quest | Unity 6000.3.0f1 or higher, Arduino |     |


1. `git clone https://github.com/ahlnaes/det-group-project.git`
2. Unity Hub -> Add project from disk -> `../det-group-project/unity/` -> Open project
3. Open `MainScene.unity`
4. `Build and Run`

You also need to install the following dependencies or libraries for your project:

- Meta XR All-in-One SDK - a Unity plugin for building VR and AR experiences

## Usage

[_Usage section showing how to use your project and interact with its features. You can use examples, screenshots, gifs, or videos to demonstrate the user interface, controls, and feedback of your project. You can also provide tips, tricks, or best practices for using your project effectively._]

To experience Tombaugh Regio and interact with its features, follow the guidelines below:

- Movement: Move around physically within your space to explore the environment.
- Interacting with buttons: Use your finger or hand to poke the buttons.
- Rotating the sphere: Swipe the sphere to rotate it and view it from different angles.
- Interactive walls: Touch the walls to trigger reactive effects.

Tips:

- Make sure you have enough physical space to move safely.
- Interact slowly and deliberately for better tracking accuracy.


## References

### Materials
#### Audio
- Ambient sound: https://cdn.pixabay.com/download/audio/2022/03/09/audio_74197cd1b9.mp3?filename=freesound_community-space-rumble-29970.mp3
- Music: Tombaugh Regio by Lucas Ahlnäs

#### Textures
- Texturelabs_Metal_136L.jpg https://texturelabs.org/textures/metal_136/
- https://substance3d.adobe.com/community-assets
- HDRI https://www.spacespheremaps.com/wp-content/uploads/HDR_multi_nebulae_1.hdr
- Pluto: 
  - https://assets.science.nasa.gov/content/dam/science/psd/photojournal/pia/pia11/pia11707/PIA11707.tif
  - https://asc-pds-services.s3.us-west-2.amazonaws.com/mosaic/Pluto_NewHorizons_Global_Mosaic_300m_Jul2017_8bit.tif
  - https://asc-pds-services.s3.us-west-2.amazonaws.com/mosaic/Pluto_NewHorizons_Global_DEM_300m_Jul2017_16bit.tif

#### Font
- Orbit https://fonts.google.com/specimen/Orbit

### Tools used
- Unity
- Blender
- Autodesk Maya
- Adobe Substance Painter
- GIMP
- Figma
- ESP32

Some of the code required for the audio-reactive system in this project proved to have a complexity level beyond the scope of the course during which this project was created. [Claude](https://claude.ai) by Anthropic was used as code help in these situations, and documentation of these processes was created in order to gain a surface level understanding and resources for further learning: [Audio Analyser](/docs/Audio%20Analyser%20Documentation%20(AI%20Generated)/Audio%20Analyser.md). Sources used:
- Cooley, J.W. & Tukey, J.W. (1965). An algorithm for the machine calculation of complex Fourier series. _Mathematics of Computation, 19_(90), 297–301. https://doi.org/10.1090/S0025-5718-1965-0178586-1
- Harris, F.J. (1978). On the use of windows for harmonic analysis with the discrete Fourier transform. _Proceedings of the IEEE, 66_(1), 51–83. https://doi.org/10.1109/PROC.1978.10837
- Bello, J.P. et al. (2005). A tutorial on onset detection in music signals. _IEEE Signal Processing Magazine, 22_(5), 23–41. https://doi.org/10.1109/MSP.2005.1511798

## Contributors

- Anna Ørbeck
- Chuck Long Ching
- Lucas Ahlnäs
- Tindra Heurlin
