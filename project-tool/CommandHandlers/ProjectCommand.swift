//
//  ProjectCommand.swift
//  project-tool
//
//  Created by Simeon Leifer on 7/29/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

class ProjectCommand: Command {
    override func run(cmd: ParsedCommand) {
        // TODO: (SKL) impl

        if cmd.option("--root") != nil {
        }

        if cmd.option("--finder") != nil {
        }
        if cmd.option("--launchbar") != nil {
        }
        if cmd.option("--sublime") != nil {
        }
        if cmd.option("--tower") != nil {
        }
        if cmd.option("--xcode") != nil {
        }

    }
}


/*

 type WorkspaceSchemes struct {
 Workspace Workspace
 }

 type Workspace struct {
 Name    string
 Schemes []string
 }

 func expandTilde(path string) (string, error) {
 if len(path) == 0 || path[0] != '~' {
 return path, nil
 }

 usr, err := user.Current()
 if err != nil {
 return "", err
 }
 return filepath.Join(usr.HomeDir, path[1:]), nil
 }

 func runCmdEcho(cmdText string) {
 parts := strings.Fields(cmdText)
 head := parts[0]
 parts = parts[1:len(parts)]

 cmd := exec.Command(head, parts...)
 cmdReader, err := cmd.StdoutPipe()
 if err != nil {
 fmt.Fprintln(os.Stderr, "Error creating StdoutPipe for Cmd", err)
 os.Exit(1)
 }
 cmdReader2, err2 := cmd.StderrPipe()
 if err2 != nil {
 fmt.Fprintln(os.Stderr, "Error creating StderrPipe for Cmd", err2)
 os.Exit(1)
 }

 scanner := bufio.NewScanner(cmdReader)
 go func() {
 for scanner.Scan() {
 fmt.Printf("%s\n", scanner.Text())
 }
 }()

 scanner2 := bufio.NewScanner(cmdReader2)
 go func() {
 for scanner2.Scan() {
 fmt.Printf("%s\n", scanner2.Text())
 }
 }()

 err = cmd.Start()
 if err != nil {
 fmt.Fprintln(os.Stderr, "Error starting Cmd", err)
 os.Exit(1)
 }

 err = cmd.Wait()
 if err != nil {
 fmt.Fprintln(os.Stderr, "Error waiting for Cmd", err)
 os.Exit(1)
 }
 }

 func runCmd(cmd string) string {
 parts := strings.Fields(cmd)
 head := parts[0]
 parts = parts[1:len(parts)]

 out, err := exec.Command(head, parts...).Output()
 if err != nil {
 fmt.Printf("%s", err)
 }
 return strings.TrimSpace(string(out))
 }

 func runCmdJson(cmd string, v interface{}) error {
 parts := strings.Fields(cmd)
 head := parts[0]
 parts = parts[1:len(parts)]

 out, err := exec.Command(head, parts...).Output()
 if err != nil {
 fmt.Printf("%s", err)
 return err
 }
 err = json.Unmarshal(out, v)
 if err != nil {
 fmt.Printf("%s", err)
 return err
 }
 return nil
 }

 func shallowDirectory(path string) []string {
 files, err := ioutil.ReadDir(path)
 if err != nil {
 return make([]string, 0)
 }

 names := make([]string, len(files))
 for i, v := range files {
 names[i] = v.Name()
 }

 return names
 }

 func Index(vs []string, t string) int {
 for i, v := range vs {
 if v == t {
 return i
 }
 }
 return -1
 }

 func Include(vs []string, t string) bool {
 return Index(vs, t) >= 0
 }

 func findXcodeProject(path string) string {
 files := shallowDirectory(path)
 var project string = ""

 for _, v := range files {
 if filepath.Ext(v) == ".xcodeproj" && len(project) == 0 {
 project = filepath.Join(path, v)
 }
 if filepath.Ext(v) == ".xcworkspace" {
 project = filepath.Join(path, v)
 }
 }
 return project
 }

 func findGitRoot() string {
 dir := runCmd("git rev-parse --show-toplevel")
 if strings.HasPrefix(dir, "fatal:") {
 return ""
 }
 return dir
 }

 func openFinder() {
 runCmd("open .")
 }

 func openLaunchBar() {
 runCmd("open -a LaunchBar .")
 }

 func openSubimeText() {
 runCmd("subl .")
 }

 func openTower() {
 if _, err := os.Stat(".git"); err == nil {
 runCmd("gittower .")
 } else {
 fmt.Println("Current directory is not the root of a git repository.")
 }
 }

 func openXcode() {
 project := findXcodeProject(".")
 if len(project) == 0 {
 fmt.Println("No Xcode project in current directory.")
 } else {
 cmd := fmt.Sprintf("open %v", project)
 runCmd(cmd)
 }
 }

 func buildXcode(configurationFlags, destinationFlags string) {
 project := findXcodeProject(".")
 if len(project) == 0 {
 fmt.Println("No Xcode project in current directory.")
 } else {
 if filepath.Ext(project) == ".xcodeproj" {
 cmd := fmt.Sprintf("xcodebuild%v%v", configurationFlags, destinationFlags)
 runCmdEcho(cmd)
 } else {
 cmd := fmt.Sprintf("xcodebuild -list -workspace %v -json", project)
 var schemes WorkspaceSchemes
 err := runCmdJson(cmd, &schemes)
 if err != nil {
 fmt.Printf("%s", err)
 return
 }
 scheme := schemes.Workspace.Name
 if Include(schemes.Workspace.Schemes, scheme) == false {
 scheme = schemes.Workspace.Schemes[0]
 }
 schemeFlags := fmt.Sprintf(" -workspace %v -scheme %v", project, scheme)
 cmd = fmt.Sprintf("xcodebuild%v%v%v", schemeFlags, configurationFlags, destinationFlags)
 fmt.Println("+++")
 fmt.Println(cmd)
 fmt.Println("---")
 runCmdEcho(cmd)
 }
 }
 }

 func validateXcodeBuildDestination() string {
 failed := false
 if *inapp == true {
 if *inbin == true || *indesk == true {
 failed = true
 } else {
 return " DEPLOYMENT_LOCATION=YES DSTROOT=/ INSTALL_PATH=/Applications"
 }
 }
 if *inbin == true {
 if *inapp == true || *indesk == true {
 failed = true
 } else {
 path, _ := expandTilde("~/bin")
 return fmt.Sprintf(" DEPLOYMENT_LOCATION=YES DSTROOT=/ INSTALL_PATH=%v", path)
 }
 }
 if *indesk == true {
 if *inbin == true || *inapp == true {
 failed = true
 } else {
 path, _ := expandTilde("~/Desktop")
 return fmt.Sprintf(" DEPLOYMENT_LOCATION=YES DSTROOT=/ INSTALL_PATH=%v", path)
 }
 }
 if failed == true {
 fmt.Println("At most one destination can be specified (applications, bin, desktop)")
 os.Exit(-1)
 }
 return ""
 }

 func main() {
 atLeastOne := false
 kingpin.Version("0.0.1")
 cmd, _ := app.Parse(os.Args[1:])

 dir := "."

 if *root == true {
 dir = findGitRoot()
 if len(dir) == 0 {
 fmt.Println("not in a git repository.")
 os.Exit(-1)
 }
 }

 os.Chdir(dir)

 switch cmd {
 case xcodebuild.FullCommand():
 configurationFlags := " -configuration Debug"
 if *release == true {
 configurationFlags = " -configuration Release"
 }
 destinationFlags := validateXcodeBuildDestination()
 buildXcode(configurationFlags, destinationFlags)
 return
 }

 if *finder == true {
 atLeastOne = true
 openFinder()
 }
 if *launchbar == true {
 atLeastOne = true
 openLaunchBar()
 }
 if *sublime == true {
 atLeastOne = true
 openSubimeText()
 }
 if *tower == true {
 atLeastOne = true
 openTower()
 }
 if *xcode == true {
 atLeastOne = true
 openXcode()
 }

 if atLeastOne == false {
 kingpin.Usage()
 }
 }
 */
