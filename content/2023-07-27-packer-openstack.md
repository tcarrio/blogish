+++
title = "Contributing to Open Source: A Stab at Go"
slug = "open-source-a-go-story"
date = 2023-07-28

[extra]
author = "Tom Carrio"

[taxonomies]
tags = ["open source", "coding", "packer", "openstack"]
+++

In 2018, I had been diving further into Go, a relatively new language at the time from Google. I was interested in taking it a step further and contributing to a well known and professional open source project based in Go from a reputable team that could provide me reviews and advice. As a system admin and software engineer, I was already familiar with the tool [Packer] from HashiCorp and had used it personally on several occasions. Based on this, I decided to start there.

## Finding work

With open source code, and especially in a well maintained project, it is very straightforward to find feature requests and bugs that need help. So, I dug through their [Issue List on GitHub](https://github.com/hashicorp/packer/issues). I found a [feature request][] I thought was interesting regarding the [OpenStack] integration for Packer.

> Add support to select most recent source image when name is provided

This was something that felt very approachable to me, for the following reasons:

1. An enhancement of existing code
2. A feature that has been implemented for an existing integration

I wasn't at the point of making large architectural decisions around these things with Go, so these provided me certain handrails to getting an initial change request proposal together.

## Planning

I discussed with other members of the community on the issue to determine further requirements and design strategy. After digging through the existing code for OpenStack, I discovered multiple components around this integration. I'll go through each of the parts I had deemed necessary to research to scope out the required changes.

### Researching the OpenStack API

The OpenStack API was going to be the primary gateway to implementing this functionality- supposing they did not offer the adequate functionality to implement this it would be a non-starter. As such, I started there, in the [OpenStack API documentation][].
The component responsible for serving images in OpenStack is [glance], an image service where users can upload and also discover assets. The image services support discovering, registering, and retrieving virtual machine images and exposes a REST API for both querying metadata and retrieving images. The [OpenStack image v2 documentation][] covered the available endpoints, including a [List Images API][].
The image API allows for additional query parameters to be passed in to filter and sort results. The important query parameters I identified include `limit`, `sort_key`, and `sort_dir`.

With the following query, it would be possible to search by an image name and return at most one result, which would be the most recent image created with that name:

```url
?sort_key=created_at&sort_dir=desc&limit=1
```

### Scoping out Packer changes

#### API calls

OpenStack support was already built in to Packer, so this was already a solved problem. In terms of scoping out what changes would be necessary here, I primarily wanted to determine whether there was an internal implementation to Packer for calling and handling responses from the OpenStack API or if they were utilizing some library for accomplishing this. I found the [gophercloud] package was being used in Packer already, so how I would interact with the API would be through that library. It also meant that if there was not support for the V2 API, I would likely be contributing a change to gophercloud in order to pull that update into Packer to support the OpenStack changes.

My initial review of the gophercloud code led me to believe that the image v2 API was not supported, so I [opened an issue on their project](https://github.com/gophercloud/gophercloud/issues/1111). In actuality it had implemented both the older compute API that allowed for listing images as well as the new glance service's API, and `@jtopjian` was very helpful in pointing me to the correct code in the library for API v2. This library has a `ListOpts` struct which is passed to marshal the query string dynamically.

Within the Packer issue, I was also getting good feedback around the gophercloud library and its capabilities for the image V2 API. With all of that squared away, I was assured in utilizing the existing library for this new feature.

#### Packer configuration

Another required change to support this functionality would be in the configuration file schema and its handling in the Packer executable. The configuration file would need to provide support for a `source_image_filter` attribute that would allow dynamically generating the query, similar to the `source_ami_filter` implementation for AWS. The configuration file could be advanced and allow for a full `ListOpts` structure to be passed in or simplified with a `most_recent_image` boolean flag. I continued to vocalize my design ideas in the Packer issue, and while waiting on feedback I started off on the solution.

### Implementation

The start of my work was on the configuration file updates. This would then be passed into the new functionality. After updating the structure, I began work on the `image_query.go` file. This was my first time working with the Reflection API in Go, and most languages provide some mechanism around this and it all falls under the umbrella of metaprogramming. My first pass in the PR was pretty rudimentary, and not having an OpenStack environment limited my ability to run a live test of my changes. All I had to go on were docs.

#### Testing

Never forget to test your code. There are very few open source projects I have seen that do not have automated testing and test coverage _especially_ those run by corporations. The software needs to work, and stay working. Refactoring should feel safe, and if a breaking change is included it should be detected without anyone manually running your code. With the advent of DevOps and automation came a bright new age for software engineering- and continuous integration in your project ensures that you detect code smells and bugs faster than ever.

### Iteration

I prefaced this post with an important note: I was not a Go expert. In fact, I'm still not- it's a tool I've used in a few scenarios over the past 5 years but it's never been my primary language in open source or professional work. So, unsurprisingly, I had feedback on my changes. This is a very good thing, because getting feedback on our work is one of the greatest ways we learn. We receive insight into design patterns, functionality we didn't know existed, or new topics we hadn't dove into before. We don't know what we don't know, and someone being there to tell you what those things are is absolutely invaluable.

I went through several iterations of the work over the next **month**. `@rickard-von-essen` was immensely helpful during this code review, and I received a lot of support from other team members at Packer throughout the entire process too. It was an absolute joy to work on, and I was very happy with the result. The code hooked into the `packer validate` functionality, worked smoothly with the Image V2 API, applied defensive tactics on inputs, was well tested, and provided clear documentation.

### The final work

For reference, the full PR changes can be found [here](https://github.com/hashicorp/packer/pull/6490/files).

```diff go
commit 70cfafb75c09d5ea54dccffb699b3e487ea7320a
Merge: bb319fb1e e2fe5cd77
Author: Rickard von Essen <rickard.von.essen@gmail.com>
Date:   Thu Aug 23 12:41:06 2018 +0200

    Merge pull request #6490 from tcarrio/most-recent-image-openstack
    
    OpenStack source image search filter

diff --git a/builder/openstack/builder.go b/builder/openstack/builder.go
index 2938d67c0..638dcc8ba 100644
--- a/builder/openstack/builder.go
+++ b/builder/openstack/builder.go
@@ -86,6 +86,12 @@ func (b *Builder) Run(ui packer.Ui, hook packer.Hook, cache packer.Cache) (packe
 			PrivateKeyFile:       b.config.RunConfig.Comm.SSHPrivateKey,
 			SSHAgentAuth:         b.config.RunConfig.Comm.SSHAgentAuth,
 		},
+		&StepSourceImageInfo{
+			SourceImage:      b.config.RunConfig.SourceImage,
+			SourceImageName:  b.config.RunConfig.SourceImageName,
+			SourceImageOpts:  b.config.RunConfig.sourceImageOpts,
+			SourceMostRecent: b.config.SourceImageFilters.MostRecent,
+		},
 		&StepCreateVolume{
 			UseBlockStorageVolume:  b.config.UseBlockStorageVolume,
 			SourceImage:            b.config.SourceImage,
diff --git a/builder/openstack/run_config.go b/builder/openstack/run_config.go
index b98b65ea8..ccc87dffc 100644
--- a/builder/openstack/run_config.go
+++ b/builder/openstack/run_config.go
@@ -4,6 +4,7 @@ import (
 	"errors"
 	"fmt"
 
+	"github.com/gophercloud/gophercloud/openstack/imageservice/v2/images"
 	"github.com/hashicorp/packer/common/uuid"
 	"github.com/hashicorp/packer/helper/communicator"
 	"github.com/hashicorp/packer/template/interpolate"
@@ -18,21 +19,22 @@ type RunConfig struct {
 	SSHInterface         string              `mapstructure:"ssh_interface"`
 	SSHIPVersion         string              `mapstructure:"ssh_ip_version"`
 
-	SourceImage       string            `mapstructure:"source_image"`
-	SourceImageName   string            `mapstructure:"source_image_name"`
-	Flavor            string            `mapstructure:"flavor"`
-	AvailabilityZone  string            `mapstructure:"availability_zone"`
-	RackconnectWait   bool              `mapstructure:"rackconnect_wait"`
-	FloatingIPNetwork string            `mapstructure:"floating_ip_network"`
-	FloatingIP        string            `mapstructure:"floating_ip"`
-	ReuseIPs          bool              `mapstructure:"reuse_ips"`
-	SecurityGroups    []string          `mapstructure:"security_groups"`
-	Networks          []string          `mapstructure:"networks"`
-	Ports             []string          `mapstructure:"ports"`
-	UserData          string            `mapstructure:"user_data"`
-	UserDataFile      string            `mapstructure:"user_data_file"`
-	InstanceName      string            `mapstructure:"instance_name"`
-	InstanceMetadata  map[string]string `mapstructure:"instance_metadata"`
+	SourceImage        string            `mapstructure:"source_image"`
+	SourceImageName    string            `mapstructure:"source_image_name"`
+	SourceImageFilters ImageFilter       `mapstructure:"source_image_filter"`
+	Flavor             string            `mapstructure:"flavor"`
+	AvailabilityZone   string            `mapstructure:"availability_zone"`
+	RackconnectWait    bool              `mapstructure:"rackconnect_wait"`
+	FloatingIPNetwork  string            `mapstructure:"floating_ip_network"`
+	FloatingIP         string            `mapstructure:"floating_ip"`
+	ReuseIPs           bool              `mapstructure:"reuse_ips"`
+	SecurityGroups     []string          `mapstructure:"security_groups"`
+	Networks           []string          `mapstructure:"networks"`
+	Ports              []string          `mapstructure:"ports"`
+	UserData           string            `mapstructure:"user_data"`
+	UserDataFile       string            `mapstructure:"user_data_file"`
+	InstanceName       string            `mapstructure:"instance_name"`
+	InstanceMetadata   map[string]string `mapstructure:"instance_metadata"`
 
 	ConfigDrive bool `mapstructure:"config_drive"`
 
@@ -47,6 +49,52 @@ type RunConfig struct {
 	// Not really used, but here for BC
 	OpenstackProvider string `mapstructure:"openstack_provider"`
 	UseFloatingIp     bool   `mapstructure:"use_floating_ip"`
+
+	sourceImageOpts images.ListOpts
+}
+
+type ImageFilter struct {
+	Filters    ImageFilterOptions `mapstructure:"filters"`
+	MostRecent bool               `mapstructure:"most_recent"`
+}
+
+type ImageFilterOptions struct {
+	Name       string   `mapstructure:"name"`
+	Owner      string   `mapstructure:"owner"`
+	Tags       []string `mapstructure:"tags"`
+	Visibility string   `mapstructure:"visibility"`
+}
+
+func (f *ImageFilterOptions) Empty() bool {
+	return f.Name == "" && f.Owner == "" && len(f.Tags) == 0 && f.Visibility == ""
+}
+
+func (f *ImageFilterOptions) Build() (*images.ListOpts, error) {
+	opts := images.ListOpts{}
+	// Set defaults for status, member_status, and sort
+	opts.Status = images.ImageStatusActive
+	opts.MemberStatus = images.ImageMemberStatusAccepted
+	opts.Sort = "created_at:desc"
+
+	var err error
+
+	if f.Name != "" {
+		opts.Name = f.Name
+	}
+	if f.Owner != "" {
+		opts.Owner = f.Owner
+	}
+	if len(f.Tags) > 0 {
+		opts.Tags = f.Tags
+	}
+	if f.Visibility != "" {
+		v, err := getImageVisibility(f.Visibility)
+		if err == nil {
+			opts.Visibility = *v
+		}
+	}
+
+	return &opts, err
 }
 
 func (c *RunConfig) Prepare(ctx *interpolate.Context) []error {
@@ -75,8 +123,8 @@ func (c *RunConfig) Prepare(ctx *interpolate.Context) []error {
 		}
 	}
 
-	if c.SourceImage == "" && c.SourceImageName == "" {
-		errs = append(errs, errors.New("Either a source_image or a source_image_name must be specified"))
+	if c.SourceImage == "" && c.SourceImageName == "" && c.SourceImageFilters.Filters.Empty() {
+		errs = append(errs, errors.New("Either a source_image, a source_image_name, or source_image_filter must be specified"))
 	} else if len(c.SourceImage) > 0 && len(c.SourceImageName) > 0 {
 		errs = append(errs, errors.New("Only a source_image or a source_image_name can be specified, not both."))
 	}
@@ -111,5 +159,34 @@ func (c *RunConfig) Prepare(ctx *interpolate.Context) []error {
 		}
 	}
 
+	// if neither ID or image name is provided outside the filter, build the filter
+	if len(c.SourceImage) == 0 && len(c.SourceImageName) == 0 {
+
+		listOpts, filterErr := c.SourceImageFilters.Filters.Build()
+
+		if filterErr != nil {
+			errs = append(errs, filterErr)
+		}
+		c.sourceImageOpts = *listOpts
+	}
+
 	return errs
 }
+
+// Retrieve the specific ImageVisibility using the exported const from images
+func getImageVisibility(visibility string) (*images.ImageVisibility, error) {
+	visibilities := [...]images.ImageVisibility{
+		images.ImageVisibilityPublic,
+		images.ImageVisibilityPrivate,
+		images.ImageVisibilityCommunity,
+		images.ImageVisibilityShared,
+	}
+
+	for _, v := range visibilities {
+		if string(v) == visibility {
+			return &v, nil
+		}
+	}
+
+	return nil, fmt.Errorf("Not a valid visibility: %s", visibility)
+}
diff --git a/builder/openstack/run_config_test.go b/builder/openstack/run_config_test.go
index 6ce0cf602..f660a4e82 100644
--- a/builder/openstack/run_config_test.go
+++ b/builder/openstack/run_config_test.go
@@ -4,7 +4,9 @@ import (
 	"os"
 	"testing"
 
+	"github.com/gophercloud/gophercloud/openstack/imageservice/v2/images"
 	"github.com/hashicorp/packer/helper/communicator"
+	"github.com/mitchellh/mapstructure"
 )
 
 func init() {
@@ -127,3 +129,84 @@ func TestRunConfigPrepare_FloatingIPPoolCompat(t *testing.T) {
 		t.Fatalf("invalid value: %s", c.FloatingIPNetwork)
 	}
 }
+
+// This test case confirms that only allowed fields will be set to values
+// The checked values are non-nil for their target type
+func TestBuildImageFilter(t *testing.T) {
+
+	filters := ImageFilterOptions{
+		Name:       "Ubuntu 16.04",
+		Visibility: "public",
+		Owner:      "1234567890",
+		Tags:       []string{"prod", "ready"},
+	}
+
+	listOpts, err := filters.Build()
+	if err != nil {
+		t.Errorf("Building filter failed with: %s", err)
+	}
+
+	if listOpts.Name != "Ubuntu 16.04" {
+		t.Errorf("Name did not build correctly: %s", listOpts.Name)
+	}
+
+	if listOpts.Visibility != images.ImageVisibilityPublic {
+		t.Errorf("Visibility did not build correctly: %s", listOpts.Visibility)
+	}
+
+	if listOpts.Owner != "1234567890" {
+		t.Errorf("Owner did not build correctly: %s", listOpts.Owner)
+	}
+}
+
+func TestBuildBadImageFilter(t *testing.T) {
+	filterMap := map[string]interface{}{
+		"limit":    "3",
+		"size_min": "25",
+	}
+
+	filters := ImageFilterOptions{}
+	mapstructure.Decode(filterMap, &filters)
+	listOpts, err := filters.Build()
+
+	if err != nil {
+		t.Errorf("Error returned processing image filter: %s", err.Error())
+		return // we cannot trust listOpts to not cause unexpected behaviour
+	}
+
+	if listOpts.Limit == filterMap["limit"] {
+		t.Errorf("Limit was parsed into ListOpts: %d", listOpts.Limit)
+	}
+
+	if listOpts.SizeMin != 0 {
+		t.Errorf("SizeMin was parsed into ListOpts: %d", listOpts.SizeMin)
+	}
+
+	if listOpts.Sort != "created_at:desc" {
+		t.Errorf("Sort was not applied: %s", listOpts.Sort)
+	}
+
+	if !filters.Empty() {
+		t.Errorf("The filters should be empty due to lack of input")
+	}
+}
+
+// Tests that the Empty method on ImageFilterOptions works as expected
+func TestImageFiltersEmpty(t *testing.T) {
+	filledFilters := ImageFilterOptions{
+		Name:       "Ubuntu 16.04",
+		Visibility: "public",
+		Owner:      "1234567890",
+		Tags:       []string{"prod", "ready"},
+	}
+
+	if filledFilters.Empty() {
+		t.Errorf("Expected filled filters to be non-empty: %v", filledFilters)
+	}
+
+	emptyFilters := ImageFilterOptions{}
+
+	if !emptyFilters.Empty() {
+		t.Errorf("Expected default filter to be empty: %v", emptyFilters)
+	}
+}
diff --git a/builder/openstack/step_run_source_server.go b/builder/openstack/step_run_source_server.go
index e56218467..6bbb40eba 100644
--- a/builder/openstack/step_run_source_server.go
+++ b/builder/openstack/step_run_source_server.go
@@ -76,6 +76,12 @@ func (s *StepRunSourceServer) Run(_ context.Context, state multistep.StateBag) m
 		ServiceClient:    computeClient,
 		Metadata:         s.InstanceMetadata,
 	}
+
+	// check if image filter returned a source image ID and replace
+	if imageID, ok := state.GetOk("source_image"); ok {
+		serverOpts.ImageRef = imageID.(string)
+	}
+
 	var serverOptsExt servers.CreateOptsBuilder
 
 	// Create root volume in the Block Storage service if required.
diff --git a/builder/openstack/step_source_image_info.go b/builder/openstack/step_source_image_info.go
new file mode 100644
index 000000000..6cf3500ae
--- /dev/null
+++ b/builder/openstack/step_source_image_info.go
@@ -0,0 +1,76 @@
+package openstack
+
+import (
+	"context"
+	"fmt"
+	"log"
+
+	"github.com/gophercloud/gophercloud/openstack/imageservice/v2/images"
+	"github.com/gophercloud/gophercloud/pagination"
+	"github.com/hashicorp/packer/helper/multistep"
+	"github.com/hashicorp/packer/packer"
+)
+
+type StepSourceImageInfo struct {
+	SourceImage      string
+	SourceImageName  string
+	SourceImageOpts  images.ListOpts
+	SourceMostRecent bool
+}
+
+func (s *StepSourceImageInfo) Run(_ context.Context, state multistep.StateBag) multistep.StepAction {
+	config := state.Get("config").(Config)
+	ui := state.Get("ui").(packer.Ui)
+
+	if s.SourceImage != "" || s.SourceImageName != "" {
+		return multistep.ActionContinue
+	}
+
+	client, err := config.imageV2Client()
+
+	log.Printf("Using Image Filters %v", s.SourceImageOpts)
+	image := &images.Image{}
+	err = images.List(client, s.SourceImageOpts).EachPage(func(page pagination.Page) (bool, error) {
+		i, err := images.ExtractImages(page)
+		if err != nil {
+			return false, err
+		}
+
+		switch len(i) {
+		case 1:
+			*image = i[0]
+			return false, nil
+		default:
+			if s.SourceMostRecent {
+				*image = i[0]
+				return false, nil
+			}
+			return false, fmt.Errorf(
+				"Your query returned more than one result. Please try a more specific search, or set most_recent to true. Search filters: %v",
+				s.SourceImageOpts)
+		}
+	})
+
+	if err != nil {
+		err := fmt.Errorf("Error querying image: %s", err)
+		state.Put("error", err)
+		ui.Error(err.Error())
+		return multistep.ActionHalt
+	}
+
+	if image.ID == "" {
+		err := fmt.Errorf("No image was found matching filters: %v", s.SourceImageOpts)
+		state.Put("error", err)
+		ui.Error(err.Error())
+		return multistep.ActionHalt
+	}
+
+	ui.Message(fmt.Sprintf("Found Image ID: %s", image.ID))
+
+	state.Put("source_image", image.ID)
+	return multistep.ActionContinue
+}
+
+func (s *StepSourceImageInfo) Cleanup(state multistep.StateBag) {
+	// No cleanup required for backout
+}
diff --git a/website/source/docs/builders/openstack.html.md b/website/source/docs/builders/openstack.html.md
index a05ce3d67..28566bd0d 100644
--- a/website/source/docs/builders/openstack.html.md
+++ b/website/source/docs/builders/openstack.html.md
@@ -70,6 +70,11 @@ builder.
     is an alternative way of providing `source_image` and only either of them
     can be specified.
 
+-   `source_image_filter` (map) - The search filters for determining the base
+    image to use. This is an alternative way of providing `source_image` and
+    only one of these methods can be used. `source_image` will override the
+    filters.
+
 -   `username` or `user_id` (string) - The username or id used to connect to
     the OpenStack service. If not specified, Packer will use the environment
     variable `OS_USERNAME` or `OS_USERID`, if set. This is not required if
@@ -153,7 +158,7 @@ builder.
     Defaults to false.
 
 -   `region` (string) - The name of the region, such as "DFW", in which to
-    launch the server to create the AMI. If not specified, Packer will use the
+    launch the server to create the image. If not specified, Packer will use the
     environment variable `OS_REGION_NAME`, if set.
 
 -   `reuse_ips` (boolean) - Whether or not to attempt to reuse existing
@@ -166,6 +171,48 @@ builder.
 -   `security_groups` (array of strings) - A list of security groups by name to
     add to this instance.
 
+-   `source_image_filter` (object) - Filters used to populate filter options.
+    Example:
+
+    ``` json
+    {
+        "source_image_filter": {
+            "filters": {
+                "name": "ubuntu-16.04",
+                "visibility": "protected",
+                "owner": "d1a588cf4b0743344508dc145649372d1",
+                "tags": ["prod", "ready"]
+            },
+            "most_recent": true
+        }
+    }
+    ```
+
+    This selects the most recent production Ubuntu 16.04 shared to you by the given owner.
+    NOTE: This will fail unless *exactly* one image is returned, or `most_recent` is set to true.
+    In the example of multiple returned images, `most_recent` will cause this to succeed by selecting
+    the newest image of the returned images.
+
+    -   `filters` (map of strings) - filters used to select a `source_image`.
+        NOTE: This will fail unless *exactly* one image is returned, or `most_recent` is set to true.
+        Of the filters described in [ImageService](https://developer.openstack.org/api-ref/image/v2/), the following
+        are valid:
+
+        - name (string)
+
+        - owner (string)
+
+        - tags (array of strings)
+
+        - visibility (string)
+
+    -   `most_recent` (boolean) - Selects the newest created image when true.
+        This is most useful for selecting a daily distro build.
+
+    You may set use this in place of `source_image` If `source_image_filter` is provided
+    alongside `source_image`, the `source_image` will override the filter. The filter
+    will not be used in this case.
+
 -   `ssh_interface` (string) - The type of interface to connect via SSH. Values
     useful for Rackspace are "public" or "private", and the default behavior is
     to connect via whichever is returned first from the OpenStack API.
```

<!-- References -->

[feature request]: https://github.com/hashicorp/packer/issues/6464
[gophercloud]: http://gophercloud.io/
[OpenStack API documentation]: https://developer.openstack.org/api-ref
[OpenStack image v2 documentation]: https://developer.openstack.org/api-ref/image/v2/
[List Images API]: https://docs.openstack.org/api-ref/image/v2/?expanded=list-images-detail#list-images
[OpenStack]: https://www.openstack.org/
[Packer]: https://www.packer.io/