#!/usr/bin/env python3

import apt
import re

def sanitize_name(name):
    """Sanitize package names for Graphviz compatibility"""
    return re.sub(r'[^a-zA-Z0-9]', '_', name)

def generate_graphviz():
    print("digraph G {")
    print("    // Package Dependencies Graph")
    
    # Initialize the apt cache
    cache = apt.Cache()
    
    # Track processed dependencies to avoid duplicates
    processed = set()
    
    for pkg in cache:
        if pkg.is_installed:
            pkg_name = sanitize_name(pkg.name)
            pkg_version = pkg.installed.version
            
            # Create a node for the package with its version
            print(f'    {pkg_name} [label="{pkg.name}\\n{pkg_version}"];')
            
            for dep in pkg.installed.dependencies:
                # dep.rawstr looks like "libfontconfig1 >= 2.12.6"
                # Parse the dependency string
                dep_parts = dep.rawstr.split(' ', 1)
                dep_name = sanitize_name(dep_parts[0])
                version_constraint = dep_parts[1] if len(dep_parts) > 1 else ""
                
                # Create a unique edge identifier
                edge_id = f"{pkg_name}-{dep_name}"
                if edge_id not in processed:
                    # Add the dependency relationship
                    print(f'    {pkg_name} -> {dep_name} [label="{version_constraint}"];')
                    processed.add(edge_id)
    
    print("}")
    
if __name__ == "__main__":
    generate_graphviz()
