==============================
Bosch SMI230 IIO driver
==============================

1. Overview
===========

The driver is intended to work on Bosch SMI230 Inertial Sensor for Non-Safety Automotive Applications.
The SMI230 is a combined triaxial accelerometer (ACC) and triaxial gyroscope (GYR) for non-safety related applications, e.g. for in-dash navigation in the passenger compartment. Within one package, the SMI230 offers the detection of acceleration and angular rate for the x-, y-, and z-axis. The digital standard serial peripheral interface (SPI) of the SMI230 allows for bi-directional data transmission. To increase flexibility, both gyroscope and accelerometer can be operated individually, but can also be tied together for data synchronization purposes.

2. Hardware Setup
====================

.. important:: This Hardware Setup serves as a quick startup kit, to help the user to run and understand the driver. It is for demonstration purposes, not supposed to be used in a production environment.

2.1 Hardware Components:
-------------------------

#. Linux Host Board
#. SMI230 sensor + Shuttleboard + Motherboard (acquirable from Bosch)
#. connection cable (female to female)
#. a mini SD card


   
2.2 Cable Connection
----------------------

::
   
     .................................                      .................................          
    .?^^^^^^^^^^~~~~~~~~^^^^^^^^^^^^^~?       VDD          !!^^^^^^^^^~~~~~~~~~~~~~~^^^^^^^^7~         
    :?          Host Board            Y~~~~~~~~~~~~~~~~~~~~J~ 2    SMI230 Mother Board      !!         
    :?                               .J       GND          ?^                               !~         
    :?                               .Y~~~~~~~~~~~~~~~~~~~~J^ 3                             !~         
    :?                               .J                    7^                               !~         
    :?                               .J       MOSI         7^                               !~         
    :?                               .Y~~~~~~~~~~~~~~~~~~~~J~ 5                             !~         
    :?                               .J       MISO         ?^                               !~         
    :?                               .Y~~~~~~~~~~~~~~~~~~~~J~ 4                             !~         
    :?                               .Y       SCLK         J~                               !~         
    :?                               .J~~~~~~~~~~~~~~~~~~~~?~ 6                             !~         
    :?                               .Y      SPI CE0       J~                               !~         
    :?                               .Y~~~~~~~~~~~~~~~~~~~~J~ 8                             !~         
    :?                               .J      SPI CE1       7^                               !~INT1      
    :?                               .J~~~~~~~~~~~~~~~~~~~~7^ 14                         21 !~~~~~~~  
    :?                               .J                    7^                               !~     |
    :?                               .J                    7^                               !~INT3 |
    :?                               .J      INT2          7^                            22 !~~~~~~~  
    :?                               .Y~~~~~~~~~~~~~~~~~~~~J^ 20                            !~         
    :?                               .J      INT4          ?^                               !~         
    :?                                Y~~~~~~~~~~~~~~~~~~~~J^ 19                            !~         
    :J...............................:J                    7~...............................7~         
     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                    :^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^.
  

2.3 First Startup
----------------------

#. Write Linux Image (32 bit) to SD Card
#. Insert SD Card Host Board and power on
#. Enable SSH on Host Board
#. Switch the Bus selection to SPI on mother board. The green LED shall be on

   
3. Software Setup
====================


3.1 Required Software
----------------------

#. Linux kernel (choose kernel branch rpi-5.15.y)  https://github.com/raspberrypi/linux
#. SMI230 IIO Linux driver   https://github.com/boschmemssolutions/SMI230-Linux-Driver-IIO
#. Linux environment (native or as VM) 

.. note:: We do not recommend to build the driver with Linux kernel directly on host board. This takes too long. Build it on PC is much faster. Since the toolchain is Linux based, a Linux environment is required. We use Ubuntu 20.04.1 LTS

- Install Toolchain and dependences  

::

   sudo apt install crossbuild-essential-armhf
   sudo apt install git bc bison flex libssl-dev make libc6-dev libncurses5-dev
   
  
- Clone Linux kernel 

::

  git clone --depth=1 --branch <branch_name> https://github.com/raspberrypi/linux

We use kernel v5.15, replace <branch_name> with "rpi-5.15.y"

- Clone SMI230 IIO Linux driver

::
  
  git clone --depth=1  https://github.com/boschmemssolutions/SMI230-Linux-Driver-IIO.git



3.2 Build SMI230 IIO Linux driver
-----------------------------------

Integrate Linux driver into Linux kernel
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- Copy source code into Linux kernel


::

  cp SMI230-Linux-Driver-IIO/drivers/iio/accel/*.c linux/drivers/iio/accel
  cp SMI230-Linux-Driver-IIO/drivers/iio/accel/*.h linux/drivers/iio/accel
  cp SMI230-Linux-Driver-IIO/drivers/iio/gyro/*.c linux/drivers/iio/gyro
  cp SMI230-Linux-Driver-IIO/drivers/iio/gyro/*.h linux/drivers/iio/gyro

- Add entry in accel Kconfig

Open linux/drivers/iio/accel/Kconfig and add the SMI230 entry at bottom

.. code-block:: kconfig

	config IIO_SMI230_ACC
		tristate "Bosch Sensor SMI230 Accelerometer"
		depends on (I2C || SPI_MASTER)
		select IIO_BUFFER
		select IIO_TRIGGERED_BUFFER
		help
		  Build driver for Bosch SMI230 tri-axis accelerometer sensor.

	choice
		prompt "Select communication interface"
		depends on IIO_SMI230_ACC
		help
		  Note: SPI and I2C are not supported at the same time, that is to say:
		  Choose either SPI or I2C to build the driver.

	    config IIO_SMI230_ACC_SPI
			bool "Enable SPI connection"
			depends on SPI_MASTER

	    config IIO_SMI230_ACC_I2C
			bool "Enable I2C connection"
			depends on I2C
	endchoice

	choice
		prompt "Select ACC interrupt source"
		depends on IIO_SMI230_ACC
		default IIO_SMI230_ACC_INT2

	    config IIO_SMI230_ACC_INT1
			bool "use int1 as source"
			help
		 	  This enables INT1 as source for ACC

	    config IIO_SMI230_ACC_INT2
			bool "use int2 as source"
			help
		 	  This enables INT2 as source for ACC
	endchoice

	choice
		prompt "Select ACC interrupt behaviour"
		depends on IIO_SMI230_ACC
		default IIO_SMI230_ACC_PUSH_PULL
	
		config IIO_SMI230_ACC_PUSH_PULL
			bool "push-pull mode"
			help
			  Use push-pull mode for interrupt pin.
		  
		config IIO_SMI230_ACC_OPEN_DRAIN
			bool "open-drain mode"
			help
			  Use open-drain mode for interrupt pin. Pull-up resistor needed!
	endchoice

	choice
		prompt "Select ACC interrupt level"
		depends on IIO_SMI230_ACC
		default IIO_SMI230_ACC_ACTIVE_HIGH
	
		config IIO_SMI230_ACC_ACTIVE_LOW
			bool "active low"
			help
			  Interrupt signal is active low or falling edge.
		  
		config IIO_SMI230_ACC_ACTIVE_HIGH
			bool "active high"
			help
			  Interrupt signal is active high or rising edge.
	endchoice

	config IIO_SMI230_ACC_FIFO
		bool "SMI230 ACC FIFO enable"
		depends on IIO_SMI230_ACC
		help
		 enable ACC FIFO feature.

	choice
		prompt "Select ACC FIFO interrupt type"
		depends on IIO_SMI230_ACC && IIO_SMI230_ACC_FIFO

	    config IIO_SMI230_ACC_FIFO_WM
			bool "use watermark threshold to generate interrupt"

	    config IIO_SMI230_ACC_FIFO_FULL
			bool "generate interrupt when FIFO is full"
	endchoice

	config IIO_SMI230_ACC_MAX_BUFFER_LEN
		depends on IIO_SMI230_ACC
		int "configue read buffer size"
		default "1024"
		help
		  Considering using FIFO, 1024 bytes are big enough for most cases. Do not change this value if not sure.

- Add entry in gyro Kconfig

Open linux/drivers/iio/gyro/Kconfig and add the SMI230 entry at bottom

.. code-block:: kconfig
	
	config SMI230_GYRO
		tristate "BOSCH SMI230 Gyro Sensor"
		depends on (I2C || SPI_MASTER)
		select IIO_BUFFER
		select IIO_TRIGGERED_BUFFER
		help
		  Say yes here to build support for BOSCH SMI230GYRO Tri-axis Gyro Sensor
		  driver connected via I2C or SPI.

	choice
	        prompt "Select communication interface"
	        depends on SMI230_GYRO
	        help
	          Note: SPI and I2C are not supported at the same time, that is to say:
	          Choose either SPI or I2C to build the driver.

	    config SMI230_GYRO_SPI
 	       bool "Enable SPI connection"
 	       depends on SPI_MASTER
	    config SMI230_GYRO_I2C
	        bool "Enable I2C connection"
	        depends on I2C
	endchoice

	choice
	        prompt "Select working mode"
	        depends on SMI230_GYRO

	    config SMI230_GYRO_NEW_DATA
	        bool "New data"
	        help
			interrupt comes once new data is available
	    config SMI230_GYRO_FIFO
 	       bool "FIFO"
	        help
			interrupt comes once data reaches certain FIFO watermark or FIFO full
	endchoice

	choice
		prompt "Select GYRO interrupt source"
		depends on (!SMI230_DATA_SYNC) && SMI230_GYRO
		default SMI230_GYRO_INT4

	    config SMI230_GYRO_INT3
		bool "use int3 as source"

	    config SMI230_GYRO_INT4
		bool "use int4 as source"
	endchoice

	choice
		prompt "Select GYRO interrupt edge"
		depends on (!SMI230_DATA_SYNC) && SMI230_GYRO
		default SMI230_GYRO_INT_ACTIVE_HIGH

	    config SMI230_GYRO_INT_ACTIVE_HIGH
		bool "interrupt is on raising edge"

	    config SMI230_GYRO_INT_ACTIVE_LOW
		bool "interrupt is on falling edge"

	endchoice

	config SMI230_MAX_BUFFER_LEN
	        int "configue read buffer size"
	        default "1024"
	        help
	          Considering using FIFO, 1024 bytes are big enough for most cases. Do not change this value if not sure.	
	
- Add entry in accel Makefile	
	
Open linux/drivers/iio/accel/Makefile and add the SMI230 entry at bottom	
	
.. code-block:: makefile

	obj-$(CONFIG_IIO_SMI230_ACC) += smi230_acc.o
	smi230_acc-objs := smi230_acc_core.o

	ifeq ($(CONFIG_IIO_SMI230_ACC_I2C),y)
		smi230_acc-objs += smi230_acc_i2c.o
	else
		smi230_acc-objs += smi230_acc_spi.o
	endif	
	
- Add entry in gyro Makefile	
	
Open linux/drivers/iio/gyro/Makefile and add the SMI230 entry at bottom	

.. code-block:: makefile

	obj-$(CONFIG_SMI230_GYRO) += smi230_gyro.o
	smi230_gyro-objs := smi230_gyro_core.o
	ifeq ($(CONFIG_SMI230_GYRO_I2C),y)
		smi230_gyro-objs += smi230_gyro_i2c.o
	else        
		smi230_gyro-objs += smi230_gyro_spi.o
	endif

- Change deveice tree overlay	
	
Open linux/arch/arm/boot/dts/overlays/spi-rtc-overlay.dts and change the content as following
	
::

	/dts-v1/;
	/plugin/;

	/ {
		compatible = "brcm,bcm2835";

		fragment@0 {
			target = <&spidev0>;
			__dormant__ {
				status = "disabled";
			};
		};
	
		fragment@1 {
			target = <&spidev1>;
			__dormant__ {
				status = "disabled";
			};
		};
	
		fragment@2 {
			target = <&spi0>;
			__dormant__ {
				#address-cells = <1>;
				#size-cells = <0>;
				status = "okay";
			
				smi230acc@0 {
					compatible = "BOSCH,SMI230ACC";
					spi-max-frequency = <8000000>;
					reg = <0>;
					gpio_irq = <&gpio 26 0>;
				};
			};
		};
	
		fragment@3 {
			target = <&spi0>;
			__dormant__ {
				#address-cells = <1>;
				#size-cells = <0>;
				status = "okay";
			
				smi230gyro@1 {
					compatible = "BOSCH,SMI230GYRO";
					spi-max-frequency = <8000000>;
					reg = <1>;
					gpio_irq = <&gpio 20 0>;
				};
			};
		};

		__overrides__ {
			smi230acc = <0>, "=0=2";
			smi230gyro = <0>, "=1=3";
		};
	};  

Build SMI230 Linux driver with the kernel
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
- Config SMI230 Linux driver

::

  cd linux
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- bcm2709_defconfig
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig

Activate the option as following

  
.. hint:: To activate an option, press "y" on the option. A \* appears, which means this option is activated as part of the kernel. Alternatively we can press "m" on the option. A "M" appears, which means this option is activated as kernel module (not as part of the kernel). Therefore we need to manually install the kernel module by ourself.

::

  Device Drivers -->	
	<*>Industrial I/O support  --->
		-*-     Industrial I/O buffering based on kfifo
		
		-*-     Industrial I/O triggered buffer support
		
		Accelerometers  --->
			<*> Bosch Sensor SMI230 Accelerometer
		
		Digital gyroscope sensors  --->
			<*> BOSCH SMI230 Gyro Sensor
		
	
- Build SMI230 Linux driver	

::

  make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
	
.. note:: Build process takes quite long on the first time. To reduce the build time, we use the option "-j4". This is the option to enable the build process to be executed parallelly in 4 threads. To improve the parallel execution, just give a big number e.g. "-j6". How many parallel thread to use is dependent on your processor core number.
	

- Install the kernel with SMI230 Linux driver in SD card

insert the SD card (created in 2.3). A "boot" partition and a "rootfs" partition will be mounted. Find out the mount point. In Ubuntu the mount point looks like that

  /media/username/boot
  
  /media/username/rootfs

write the kernel with SMI230 Linux driver in SD card

::

  export KERNEL=kernel7
  export SD_BOOT_PATH=/media/username/boot
  export SD_ROOTFS_PATH=/media/username/rootfs
  sudo env PATH=$PATH make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=$SD_ROOTFS_PATH modules_install
  sudo cp $SD_BOOT_PATH/$KERNEL.img $SD_BOOT_PATH/$KERNEL-backup.img
  sudo cp arch/arm/boot/zImage $SD_BOOT_PATH/$KERNEL.img
  sudo cp arch/arm/boot/dts/*.dtb $SD_BOOT_PATH
  sudo cp arch/arm/boot/dts/overlays/*.dtb* $SD_BOOT_PATH/overlays/
  sudo cp arch/arm/boot/dts/overlays/README $SD_BOOT_PATH/overlays/

- adapt the boot configuraion

open the "config.txt" in "boot" partition, and add the following entries 

::
	
	# Uncomment some or all of these to enable the optional hardware interfaces
	dtparam=spi=on
	dtoverlay=spi-rtc,smi230acc
	dtoverlay=spi-rtc,smi230gyro

Take the SD card out and put it back in board.

4. Work with SMI230 Linux driver
=================================

- Check driver initialization

Power on the board. We firstly check if the driver was initialized properly

::

   dmesg | grep SMI230
   [    8.473601] SMI230GYRO spi0.1: Bosch Sensor SMI230GYRO hardware initialized
   [    8.487473] SMI230GYRO spi0.1: Bosch Sensor SMI230GYRO device alloced
   [    8.487783] SMI230GYRO spi0.1: Bosch Sensor SMI230GYRO trigger registered
   [    8.487822] SMI230GYRO spi0.1: Bosch Sensor SMI230GYRO trigger buffer registered
   [    8.487880] SMI230GYRO spi0.1: gpio pin 20
   [    8.488083] SMI230GYRO spi0.1: irq number 201
   [    8.488205] SMI230GYRO spi0.1: Bosch Sensor SMI230GYRO irq alloced
   [    8.492520] Bosch Sensor Device SMI230ACC initialized
   
   
If the driver was installed properly, 2 folders will be created. A number of deveice files are created in the folders. which we can use to read/write data from/to the sensor


   /sys/bus/iio/devices/iio:device0
   
   /sys/bus/iio/devices/iio:device1
   
.. note:: Folder name is assigned automatically by the system, therefore does not reflect the sensor type. There is a "name" file in the deveice folder, which we can read to find out the sensor type

::

	cd /sys/bus/iio/devices/iio:device1
	sudo su
	cat name
	SMI230ACC
	

- Work with driver using command line 

.. note:: To change sensor settings we need root access. It is not sufficient just using "sudo ..."  For the following examples we use accelerometer. Gyroscope is quite similar.

Check sensor type

::

	cd /sys/bus/iio/devices/iio:device1
	sudo su
	cat name
	SMI230ACC
	
check power mode and activate if it is suspended.

::

   cat power_mode
   suspend
   echo normal > power_mode
   cat power_mode
   normal

Read data from sensor. 

::

  cat in_accel_raw
  7797892 78 -94 8160
  cat in_accel_range
  4
  cat in_accel_sampling_frequency
  100.000000
  
Change sensor setting

::

   echo 200 > in_accel_sampling_frequency
   cat in_accel_sampling_frequency
   200.000000
   echo 8 > in_accel_range
   cat in_accel_range
   8
   
- Using driver in C code

SMI 230 Driver provides 2 interfaces for the user space program,

1. Sensor data interface: IIO Buffer. SMI230 driver writes sensor data into the IIO buffer from kernel space. Program from user space reads the data from the IIO buffer
2. Sensor Event interface: IIO Event. SMI230 driver sends IIO Event to user space to inform the program in user space that some sensor event happened. (e.g. sensor value over threshold)

ACC Example to read sensor data:

Source code: be able to find inside the linux source tree    tools/iio/iio_generic_buffer.c

Build the example

::
  
  cd tools
  make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- iio
  
Upload iio_generic_buffer in board and execute it

.. note:: For the following exsample we use accelerometer. Gyroscope is quite similar. Run iio_generic_buffer as root.  Use device number of SMI230ACC -N 1.  
  
::

  sudo ./iio_generic_buffer -N 1 -c -1 -a
  iio device number being used is 1
  iio trigger number being used is 1
  Enabling all channels
  Enabling: in_accel_y_en
  Enabling: in_accel_x_en
  Enabling: in_timestamp_en
  Enabling: in_accel_z_en
  /sys/bus/iio/devices/iio:device1 SMI230ACC-trigger
  28.000000 -118.000000 8154.000000 1665428973532193471
  41.000000 -102.000000 8181.000000 1665428973542061576
  83.000000 -88.000000 8152.000000 1665428973551912910
  92.000000 -80.000000 8165.000000 1665428973561775285
  87.000000 -90.000000 8173.000000 1665428973571636306
  101.000000 -93.000000 8162.000000 1665428973581498994
  104.000000 -95.000000 8152.000000 1665428973591361369
  89.000000 -106.000000 8163.000000 1665428973601222963
  57.000000 -97.000000 8164.000000 1665428973611084557
  [accX accY accZ time_ns]

.. hint:: Check the device number of SMI230ACC by reading "name" from deveice folder

::

	cd /sys/bus/iio/devices/iio:device1
	sudo su
	cat name
	SMI230ACC  

5. SMI230 Firmware Features
=================================

The firmware features uses IIO event to signal the user space application that some sensor event happened (e.g. sampling value over threshold). To read the event from user space, the Linux kernel provides a C program uder tools/iio. And we need to firstly complie it and upload to working board.

::

   cd tools
   make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- iio
   scp tools/iio/iio_event_monitor to your board

5.1 Anymotion
----------------------

Any-motion detection uses the absolute difference (=slope) between the current input and an acceleration reference sample to detect the motion status of the device. This feature can be used for wake-up. An interrupt is generated when the absolute difference exceeds a configurable, preset threshold for a preset duration. For more details see SMI230 TCD 7.11

.. note:: Currently the event type defined by the Linux IIO is not able to cover our firmware features. Therefore we have to map our feature event to the existed IIO event type. We map anymotion event to IIO event type **"roc"** and direction **"rising"**

anymotion configuration is able to be found under
::

  /sys/bus/iio/devices/iio:deviceX/events
  ├── in_accel_x_roc_rising_en                          // enable/disable any motion x-axis
  ├── in_accel_y_roc_rising_en                          // enable/disable any motion y-axis
  ├── in_accel_z_roc_rising_en                          // enable/disable any motion z-axis
  ├── roc_rising_period                                 // configure any motion duration
  └── roc_rising_value                                  // configure any motion threshold

enable any motion x-axis with default duration and threshold

::

   sudo su
   echo normal > /sys/bus/iio/devices/iio\:device1/power_mode
   echo 1 > /sys/bus/iio/devices/iio\:device1/events/in_accel_x_roc_rising_en
   ./iio_event_monitor SMI230ACC
   Found IIO device with name SMI230ACC with device number 1

     
Move sensor in x-axis. We will see the anymotion events as following

::

   Event: time: 1667837753823018925, type: accel(x|y|z), channel: 0, evtype: roc, direction: rising
   Event: time: 1667837753842726224, type: accel(x|y|z), channel: 0, evtype: roc, direction: rising
   Event: time: 1667837753862437586, type: accel(x|y|z), channel: 0, evtype: roc, direction: rising
   Event: time: 1667837753882149312, type: accel(x|y|z), channel: 0, evtype: roc, direction: rising
   Event: time: 1667837753901861871, type: accel(x|y|z), channel: 0, evtype: roc, direction: rising
   Event: time: 1667837753921574535, type: accel(x|y|z), channel: 0, evtype: roc, direction: rising
   
5.2 Nomotion
----------------------

No-motion detection uses the absolute slope between two consecutive acceleration signal samples to detect the static state of the device. In no-motion mode, an interrupt is generated if the slope of all enabled axes remains smaller than a preset threshold for a preset duration. For more details see SMI230 TCD 7.15

.. note:: Currently the event type defined by the Linux IIO is not able to cover our firmware features. Therefore we have to map our feature event to the existed IIO event type. We map nomotion event to IIO event type **"roc"** and direction **"falling"**

nomotion configuration is able to be found under

::

  /sys/bus/iio/devices/iio:deviceX/events
  ├── in_accel_x_roc_falling_en                          // enable/disable no motion x-axis
  ├── in_accel_y_roc_falling_en                          // enable/disable no motion y-axis
  ├── in_accel_z_roc_falling_en                          // enable/disable no motion z-axis
  ├── roc_falling_period                                 // configure no motion duration
  └── roc_falling_value                                  // configure no motion threshold

enable no motion x-axis with default duration and threshold

::

   sudo su
   echo normal > /sys/bus/iio/devices/iio\:device1/power_mode
   echo 1 > /sys/bus/iio/devices/iio\:device1/events/in_accel_x_roc_falling_en
   ./iio_event_monitor SMI230ACC
   Found IIO device with name SMI230ACC with device number 1
   Event: time: 1667845513396539597, type: accel(x&y&z), channel: 0, evtype: roc, direction: falling
   Event: time: 1667845513416250976, type: accel(x&y&z), channel: 0, evtype: roc, direction: falling
   Event: time: 1667845513435964698, type: accel(x&y&z), channel: 0, evtype: roc, direction: falling
   Event: time: 1667845513455680347, type: accel(x&y&z), channel: 0, evtype: roc, direction: falling

     
Since the sensor is static, nomation events come immediately after command execution. 
   
5.3 High-G
----------------------

The high-g interrupt is based on the comparison of acceleration data against a high-g threshold for the detection of wake-up, shock, or other high-acceleration events. The interrupt is triggered if the absolute value of acceleration data of at least one enabled axis exceeds the programmed threshold for a preset duration. For more details see SMI230 TCD 7.12

.. note:: Currently the event type defined by the Linux IIO is not able to cover our firmware features. Therefore we have to map our feature event to the existed IIO event type. We map high-g event to IIO event type **"thresh_adaptive"** , map positive acceleration to direction **"rising"**, and map negative acceleration to direction **"falling"**

high-g configuration is able to be found under

::

  /sys/bus/iio/devices/iio:deviceX/events
  ├── in_accel_x_thresh_adaptive_rising_en           // enable/disable high-g x-axis
  ├── in_accel_y_thresh_adaptive_rising_en           // enable/disable high-g y-axis
  ├── in_accel_z_thresh_adaptive_rising_en           // enable/disable high-g z-axis
  ├── thresh_adaptive_rising_hysteresis              // configure high-g hysteresis
  ├── thresh_adaptive_rising_period                  // configure high-g duration
  └── thresh_adaptive_rising_value                   // configure high-g threshold

.. note:: Please do not get confused by the configuration name. Even the name contains "rising", it's not only for positive acceleration. It's valid for both positive and negative acceleration. 

enable high-g x-axis with default hysteresis, duration and threshold

::

   sudo su
   echo normal > /sys/bus/iio/devices/iio\:device1/power_mode
   echo 1 > /sys/bus/iio/devices/iio\:device1/events/in_accel_x_thresh_adaptive_rising_en
   ./iio_event_monitor SMI230ACC
   Found IIO device with name SMI230ACC with device number 1
   
   
Strongly move sensor in x-axis for several seconds. We will see the high-g events as following (in case of positive acceleration)

::

   Event: time: 1667846375561835822, type: accel(x), channel: 0, evtype: thresh_adaptive, direction: rising
   Event: time: 1667846375566740084, type: accel(x), channel: 0, evtype: thresh_adaptive, direction: rising
   Event: time: 1667846375571704764, type: accel(x), channel: 0, evtype: thresh_adaptive, direction: rising
   Event: time: 1667846375576619964, type: accel(x), channel: 0, evtype: thresh_adaptive, direction: rising
   Event: time: 1667846375581546414, type: accel(x), channel: 0, evtype: thresh_adaptive, direction: rising

5.3 Low-G
----------------------

The low-g interrupt is based on the comparison of acceleration data against a low-g threshold, which is most useful for free-fall detection. An interrupt is generated when the magnitude of the acceleration values goes below the set low-g threshold for a preset duration. For more details see SMI230 TCD 7.13

.. note:: Currently the event type defined by the Linux IIO is not able to cover our firmware features. Therefore we have to map our feature event to the existed IIO event type. We map low-g event to IIO event type **"thresh"** and direction **"falling"**

low-g configuration is able to be found under

::

  /sys/bus/iio/devices/iio:deviceX/events
  ├── thresh_falling_en                                      // enable/disable low-g
  ├── thresh_falling_hysteresis                              // configure low-g hysteresis
  ├── thresh_falling_period                                  // configure low-g duration
  └── thresh_falling_value                                   // configure low-g threshold




enable low-g with default hysteresis, duration and threshold

::

   sudo su
   echo normal > /sys/bus/iio/devices/iio\:device1/power_mode
   echo 1 > /sys/bus/iio/devices/iio\:device1/events/thresh_falling_en
   ./iio_event_monitor SMI230ACC
   Found IIO device with name SMI230ACC with device number 1
   
   
Let the sensor have a samll free-fall. We will see the low-g events as following

::

   Event: time: 1667847250777175066, type: accel(x^2+y^2+z^2), channel: 0, evtype: thresh, direction: falling
   Event: time: 1667847250796883737, type: accel(x^2+y^2+z^2), channel: 0, evtype: thresh, direction: falling
   Event: time: 1667847250816595169, type: accel(x^2+y^2+z^2), channel: 0, evtype: thresh, direction: falling

5.4 Orientation
----------------------

The orientation detection feature gives information on an orientation change of the SMI230 with respect to the gravitational field vector g. There are the orientations face up / face down, and orthogonal to that portrait upright, landscape left, portrait upside down and landscape right. For more details see SMI230 TCD 7.14

.. note:: Currently the event type defined by the Linux IIO is not able to cover our firmware features. Therefore we have to map our feature event to the existed IIO event type. We map face up/down event to IIO event type **"change"** and portrait/landscape event to IIO event type **"mag"**

orientation configuration is able to be found under

::

  /sys/bus/iio/devices/iio:deviceX/events
  ├── change_rising_en                                     // enable/disable orientation face up/down feature
  ├── mag_en                                               // enable/disable orientation portrait/landscape
  ├── mag_hysteresis                                       // configure orientation hysteresis
  ├── mag_period                                           // configure orientation mode
  ├── mag_timeout                                          // configure orientation blocking
  └── mag_value                                            // configure orientation theta






enable portrait/landscape only

::

   sudo su
   echo normal > /sys/bus/iio/devices/iio\:device1/power_mode
   echo 1 > /sys/bus/iio/devices/iio\:device1/events/mag_en
   ./iio_event_monitor SMI230ACC
   Found IIO device with name SMI230ACC with device number 1
   
   
turn the sensor up/down/right/left, we will see the following events

::

   Event: time: 1667910697041617202, type: accel, channel: 0, evtype: mag, direction: rising
   Event: time: 1667910699447225295, type: accel, channel: 0, evtype: mag, direction: falling
   Event: time: 1667910720486024876, type: accel, channel: 0, evtype: mag
   Event: time: 1667910725573235402, type: accel, channel: 0, evtype: mag, direction: either
   
Orientation Mapping

| **Portrait Upright     -> evtype: mag, direction: rising**
| **Portrait Upside Down -> evtype: mag, direction: falling**
| **Landscape Right      -> evtype: mag (Note: there is no direction)**
| **Landscape Left       -> evtype: mag, direction: either**


enable face up/down additionally

::

   sudo su
   echo normal > /sys/bus/iio/devices/iio\:device1/power_mode
   echo 1 > /sys/bus/iio/devices/iio\:device1/events/mag_en
   echo 1 > /sys/bus/iio/devices/iio\:device1/events/change_rising_en
   ./iio_event_monitor SMI230ACC
   Found IIO device with name SMI230ACC with device number 1
   
   
turn the sensor up/left,  down/left,  down/right, ip/right, we will see the following events. Now,for each orientation change we will get 2 events

::

   Event: time: 1667911964122230457, type: accel, channel: 0, evtype: change, direction: rising
   Event: time: 1667911964122230457, type: accel, channel: 0, evtype: mag, direction: either
   Event: time: 1667911964497059999, type: accel, channel: 0, evtype: change, direction: falling
   Event: time: 1667911964497059999, type: accel, channel: 0, evtype: mag, direction: either
   Event: time: 1667911973059147751, type: accel, channel: 0, evtype: change, direction: falling
   Event: time: 1667911973059147751, type: accel, channel: 0, evtype: mag
   Event: time: 1667911974716313160, type: accel, channel: 0, evtype: change, direction: rising
   Event: time: 1667911974716313160, type: accel, channel: 0, evtype: mag
   
   
Orientation Mapping

| **Face Up   -> evtype: change, direction: rising**
| **Face Down -> evtype: evtype: change, direction: falling**


5.4 Data Synchronization
---------------------------

To achieve data synchronization on SMI230, the new data interrupt signal from the gyroscope of the SMI230 needs to be connected to one of the interrupt pins of the SMI230 accelerometer (which can be configured as input pins). The internal signal processing unit of the accelerometer uses the data ready signal from the gyroscope to synchronize and interpolate the data of the accelerometer, considering the group delay of the sensors. The accelerometer part can then notify the host of available data. With this technique, it is possible to achieve synchronized data and provide accelerometer data at an ODR up to 2 kHz. The data synchronization feature supports 100 Hz, 200 Hz, 400 Hz, 1 kHz and 2 kHz data rates. For more details see SMI230 TCD 7.10

.. note:: SMI230 Linux driver only support the application schematic defined in TCD 7.10.2. The SMI230 interrupt pins INT1 (ACC) and INT3 (GYR) have to be connected externally on the PCB. The GYR new data interrupt needs to be mapped to INT3, while INT1 needs to be configured as an input pin. For a data ready host notification, the interrupt pin INT2 (ACC) shall be used.

- Re-config ther kernel to activate data synchronization

.. hint:: To activate an option, press "y" on the option. A \* appears, which means this option is activated as part of the kernel. Alternatively we can press "m" on the option. A "M" appears, which means this option is activated as kernel module (not as part of the kernel). Therefore we need to manually install the kernel module by ourself.

::
  
  Device Drivers -->	
	<*>Industrial I/O support  --->
		-*-     Industrial I/O buffering based on kfifo
		
		-*-     Industrial I/O triggered buffer support
		
		Accelerometers  --->
			<*> Bosch Sensor SMI230 Accelerometer
			     Select operating mode (New data mode)  --->
			        ( ) New data mode
			        ( ) FIFO mode
			        (X) Data Sync mode 
		
		Digital gyroscope sensors  --->
			<*> BOSCH SMI230 Gyro Sensor
			     Select working mode (New data)  ---> 
			        ( ) New data 
			        ( ) FIFO 
			        (X) Data sync 

- Build SMI230 Linux driver	

::

  make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- zImage modules dtbs
  
- Install the kernel with SMI230 Linux driver in SD card

insert the SD card (created in 2.3). A "boot" partition and a "rootfs" partition will be mounted. Find out the mount point. In Ubuntu the mount point looks like that

  /media/username/boot
  
  /media/username/rootfs

write the kernel with SMI230 Linux driver in SD card

::

  export KERNEL=kernel7
  export SD_BOOT_PATH=/media/username/boot
  export SD_ROOTFS_PATH=/media/username/rootfs
  sudo env PATH=$PATH make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=$SD_ROOTFS_PATH modules_install
  sudo cp $SD_BOOT_PATH/$KERNEL.img $SD_BOOT_PATH/$KERNEL-backup.img
  sudo cp arch/arm/boot/zImage $SD_BOOT_PATH/$KERNEL.img
  sudo cp arch/arm/boot/dts/*.dtb $SD_BOOT_PATH
  sudo cp arch/arm/boot/dts/overlays/*.dtb* $SD_BOOT_PATH/overlays/
  sudo cp arch/arm/boot/dts/overlays/README $SD_BOOT_PATH/overlays/

Take the SD card out and put it back in board. Power on 
  
data sync configuration is able to be found under acc folder

::

  /sys/bus/iio/devices/iio:deviceX
  ├── sampling_frequency                                     // data sync output data rate
  └── sampling_frequency_available                           // vaild data sync output data rate
  

.. hint:: Check the device number of SMI230ACC by reading "name" from deveice folder

::

	cd /sys/bus/iio/devices/iio:device1
	sudo su
	cat name
	SMI230ACC  


Enable acc and set output data rate to 100 Hz

::

    sudo su
    root@raspberrypi:/home/pi# echo normal > /sys/bus/iio/devices/iio\:device1/power_mode
    root@raspberrypi:/home/pi# echo 100 > /sys/bus/iio/devices/iio\:device1/sampling_frequency
    
Read data from buffer

::

   root@raspberrypi:/home/pi# ./iio_generic_buffer -N 1 -c -1 -a
   iio device number being used is 1
   iio trigger number being used is 0
   Enabling all channels
   Enabling: in_accel_y_en
   Enabling: in_anglvel_z_en
   Enabling: in_accel_x_en
   Enabling: in_timestamp_en
   Enabling: in_anglvel_y_en
   Enabling: in_accel_z_en
   Enabling: in_anglvel_x_en
   /sys/bus/iio/devices/iio:device1 SMI230ACC-trigger
   -6.000000 -20.000000 8197.000000 -2.000000 3.000000 -2.000000 1669286887634661928
   6.000000 -13.000000 8210.000000 -1.000000 2.000000 -2.000000 1669286887644684248
   7.000000 -8.000000 8214.000000 -4.000000 3.000000 -1.000000 1669286887654704745
   6.000000 -7.000000 8212.000000 0.000000 1.000000 -2.000000 1669286887664725555
   5.000000 -20.000000 8203.000000 -3.000000 2.000000 0.000000 1669286887674767145
   -7.000000 -39.000000 8213.000000 -2.000000 4.000000 -2.000000 1669286887684766393
   -1.000000 -28.000000 8204.000000 -1.000000 1.000000 -1.000000 1669286887694787306
   -10.000000 -10.000000 8211.000000 -1.000000 2.000000 -2.000000 1669286887704806866
   -8.000000 1.000000 8195.000000 -1.000000 2.000000 -1.000000 1669286887714828249
   -28.000000 -16.000000 8199.000000 -1.000000 1.000000 -1.000000 1669286887724851610
   -18.000000 -24.000000 8207.000000 -2.000000 1.000000 -2.000000 1669286887734863149
   4.000000 -22.000000 8218.000000 -2.000000 2.000000 -1.000000 1669286887744886042
   3.000000 -20.000000 8210.000000 0.000000 4.000000 -2.000000 1669286887754906904
   13.000000 -19.000000 8209.000000 -3.000000 3.000000 -2.000000 1669286887764926203
   14.000000 -17.000000 8206.000000 -3.000000 2.000000 -3.000000 1669286887774948940
   6.000000 -6.000000 8213.000000 -2.000000 2.000000 -1.000000 1669286887784969697
   [accX_sync accY_sync accZ_sync gyroX, gyroY, gyroZ,time_ns]





