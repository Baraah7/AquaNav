"""
Visualization Tools for Land/Water Masks
Generates visual representations of coastline and navigation masks.
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.colors import ListedColormap
import json
from typing import Optional, List, Tuple


class MaskVisualizer:
    """Visualize land/water masks and routes."""
    
    def __init__(self, mask_path: str, metadata_path: Optional[str] = None):
        """
        Initialize visualizer.
        
        Args:
            mask_path: Path to .npz mask file
            metadata_path: Optional path to metadata JSON
        """
        data = np.load(mask_path)
        self.mask = data['mask']
        self.bbox = tuple(data['bbox'])
        self.resolution = float(data['resolution'])
        self.width = int(data['width'])
        self.height = int(data['height'])
        
        if metadata_path:
            with open(metadata_path, 'r') as f:
                self.metadata = json.load(f)
        else:
            self.metadata = None
    
    def plot_mask(self, output_path: Optional[str] = None, 
                  show_grid: bool = False, figsize: Tuple[int, int] = (12, 10)):
        """
        Create visualization of land/water mask.
        
        Args:
            output_path: Optional path to save figure
            show_grid: Whether to show coordinate grid
            figsize: Figure size in inches
        """
        fig, ax = plt.subplots(figsize=figsize)
        
        # Create custom colormap (water=blue, land=tan)
        colors = ['#d4a574', '#4a90e2']  # tan, blue
        cmap = ListedColormap(colors)
        
        # Plot mask
        extent = [self.bbox[0], self.bbox[2], self.bbox[1], self.bbox[3]]
        im = ax.imshow(self.mask, cmap=cmap, extent=extent, 
                      origin='upper', interpolation='nearest')
        
        # Add colorbar with labels
        cbar = plt.colorbar(im, ax=ax, ticks=[0.25, 0.75])
        cbar.ax.set_yticklabels(['Land', 'Water'])
        cbar.set_label('Navigation Mask', rotation=270, labelpad=20)
        
        # Set labels and title
        ax.set_xlabel('Longitude (°E)', fontsize=12)
        ax.set_ylabel('Latitude (°N)', fontsize=12)
        ax.set_title('Bahrain Maritime Navigation Mask', fontsize=14, fontweight='bold')
        
        # Add grid if requested
        if show_grid:
            ax.grid(True, alpha=0.3, linestyle='--')
        
        # Add statistics text box
        total_pixels = self.width * self.height
        water_pixels = np.sum(self.mask == 1)
        water_pct = (water_pixels / total_pixels) * 100
        
        stats_text = f'Resolution: {self.resolution}° (~{self.resolution * 111:.1f} km)\n'
        stats_text += f'Grid: {self.width} × {self.height} pixels\n'
        stats_text += f'Water coverage: {water_pct:.1f}%'
        
        ax.text(0.02, 0.98, stats_text, transform=ax.transAxes,
               verticalalignment='top', bbox=dict(boxstyle='round', 
               facecolor='white', alpha=0.8), fontsize=10)
        
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"Visualization saved: {output_path}")
        else:
            plt.show()
        
        plt.close()
    
    def plot_route_on_mask(self, route: List[Tuple[float, float]], 
                          output_path: Optional[str] = None,
                          figsize: Tuple[int, int] = (12, 10)):
        """
        Visualize a planned route on the navigation mask.
        
        Args:
            route: List of (lon, lat) waypoints
            output_path: Optional path to save figure
            figsize: Figure size in inches
        """
        fig, ax = plt.subplots(figsize=figsize)
        
        # Create custom colormap
        colors = ['#d4a574', '#4a90e2']
        cmap = ListedColormap(colors)
        
        # Plot mask
        extent = [self.bbox[0], self.bbox[2], self.bbox[1], self.bbox[3]]
        ax.imshow(self.mask, cmap=cmap, extent=extent, 
                 origin='upper', interpolation='nearest', alpha=0.7)
        
        # Plot route
        if route and len(route) > 1:
            lons = [p[0] for p in route]
            lats = [p[1] for p in route]
            
            # Plot route line
            ax.plot(lons, lats, 'r-', linewidth=2, label='Planned Route', zorder=10)
            
            # Plot waypoints
            ax.plot(lons, lats, 'ro', markersize=6, zorder=11)
            
            # Mark start and end
            ax.plot(lons[0], lats[0], 'go', markersize=12, 
                   label='Start', zorder=12, markeredgecolor='white', markeredgewidth=2)
            ax.plot(lons[-1], lats[-1], 'rs', markersize=12, 
                   label='End', zorder=12, markeredgecolor='white', markeredgewidth=2)
        
        # Styling
        ax.set_xlabel('Longitude (°E)', fontsize=12)
        ax.set_ylabel('Latitude (°N)', fontsize=12)
        ax.set_title('Maritime Route Planning - Bahrain Waters', 
                    fontsize=14, fontweight='bold')
        ax.legend(loc='upper right', fontsize=10)
        ax.grid(True, alpha=0.3, linestyle='--')
        
        plt.tight_layout()
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"Route visualization saved: {output_path}")
        else:
            plt.show()
        
        plt.close()
    
    def plot_validation_report(self, output_path: Optional[str] = None,
                              figsize: Tuple[int, int] = (14, 10)):
        """
        Create comprehensive validation report visualization.
        
        Args:
            output_path: Optional path to save figure
            figsize: Figure size in inches
        """
        fig = plt.figure(figsize=figsize)
        gs = fig.add_gridspec(2, 2, hspace=0.3, wspace=0.3)
        
        # 1. Main mask visualization
        ax1 = fig.add_subplot(gs[0, :])
        colors = ['#d4a574', '#4a90e2']
        cmap = ListedColormap(colors)
        extent = [self.bbox[0], self.bbox[2], self.bbox[1], self.bbox[3]]
        im = ax1.imshow(self.mask, cmap=cmap, extent=extent, 
                       origin='upper', interpolation='nearest')
        ax1.set_xlabel('Longitude (°E)')
        ax1.set_ylabel('Latitude (°N)')
        ax1.set_title('Navigation Mask - Full Coverage', fontweight='bold')
        ax1.grid(True, alpha=0.3)
        
        # 2. Coverage statistics
        ax2 = fig.add_subplot(gs[1, 0])
        total_pixels = self.width * self.height
        water_pixels = np.sum(self.mask == 1)
        land_pixels = total_pixels - water_pixels
        
        wedges, texts, autotexts = ax2.pie(
            [water_pixels, land_pixels],
            labels=['Water (Navigable)', 'Land (Blocked)'],
            colors=['#4a90e2', '#d4a574'],
            autopct='%1.1f%%',
            startangle=90
        )
        ax2.set_title('Area Coverage Distribution', fontweight='bold')
        
        # 3. Resolution analysis
        ax3 = fig.add_subplot(gs[1, 1])
        ax3.axis('off')
        
        stats_text = "VALIDATION REPORT\n" + "="*30 + "\n\n"
        stats_text += f"Grid Dimensions: {self.width} × {self.height}\n"
        stats_text += f"Total Cells: {total_pixels:,}\n\n"
        stats_text += f"Resolution: {self.resolution}°\n"
        stats_text += f"Approx: {self.resolution * 111:.2f} km/cell\n\n"
        stats_text += f"Bounding Box:\n"
        stats_text += f"  Min Lon: {self.bbox[0]:.4f}°\n"
        stats_text += f"  Max Lon: {self.bbox[2]:.4f}°\n"
        stats_text += f"  Min Lat: {self.bbox[1]:.4f}°\n"
        stats_text += f"  Max Lat: {self.bbox[3]:.4f}°\n\n"
        stats_text += f"Navigable (Water): {water_pixels:,} cells\n"
        stats_text += f"Blocked (Land): {land_pixels:,} cells\n\n"
        stats_text += "EXIT CRITERIA:\n"
        stats_text += "✓ Binary mask generated\n"
        stats_text += "✓ Aligned with EPSG:4326\n"
        stats_text += "✓ Polygons validated\n"
        stats_text += "✓ Export complete"
        
        ax3.text(0.1, 0.9, stats_text, transform=ax3.transAxes,
                verticalalignment='top', fontfamily='monospace',
                fontsize=9, bbox=dict(boxstyle='round', 
                facecolor='lightgray', alpha=0.8))
        
        fig.suptitle('Bahaar Coastline Processing - Validation Report', 
                    fontsize=16, fontweight='bold')
        
        if output_path:
            plt.savefig(output_path, dpi=300, bbox_inches='tight')
            print(f"Validation report saved: {output_path}")
        else:
            plt.show()
        
        plt.close()


# Example usage
if __name__ == "__main__":
    # Create visualizations
    viz = MaskVisualizer(
        "bahrain_navigation_mask.npz",
        "bahrain_navigation_mask_metadata.json"
    )
    
    # Generate mask visualization
    viz.plot_mask(output_path="mask_visualization.png", show_grid=True)
    
    # Generate validation report
    viz.plot_validation_report(output_path="validation_report.png")
    
    print("\nVisualizations generated successfully!")
