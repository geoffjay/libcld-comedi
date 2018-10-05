Name:           libcld-comedi
Version:        0.4.8
Release:        1%{?dist}
Summary:        GObject Configuration Library

Group:          System Environment/Libraries
License:        LGPLv3+
URL:            https://github.com/geoffjay/libcld
Source0:        %{url}/archive/v%{version}.tar.gz
#Source0:        %{name}-%{version}.tar.xz

BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(gee-0.8)
BuildRequires:  pkgconfig(json-glib-1.0)
BuildRequires:  pkgconfig(libxml-2.0)
BuildRequires:  pkgconfig(libcld-1.0)
BuildRequires:  pkgconfig(comedilib)
BuildRequires:  meson
BuildRequires:  ninja-build
%if 0%{?epel}
%else
BuildRequires:  python3-sphinx
%endif
BuildRequires:  vala
BuildRequires:  vala-tools
#BuildRequires:  valadoc

%description
Cld is a library for creating GObject-based configurations and classes for
loading and working with XML and JSON files.

It is written in Vala and can be used like any GObject-based C library.

%package        devel
Summary:        Development files for %{name}
Group:          Development/Libraries
Requires:       %{name}

%description    devel
The %{name}-devel package contains libraries and header files for
developing applications that use %{name}.

%prep
%autosetup -n %{name}-%{version}

%build
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:./deps
%meson
%meson_build

%install
%meson_install

%check
%meson_test

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%files
%doc README.md COPYING
%{_datarootdir}/*
%{_libdir}/*
%exclude %{_libdir}/pkgconfig/*

%files devel
%{_includedir}/*
%{_libdir}/pkgconfig/*
%{_datadir}/vala/*

%changelog
* Thu Oct 4 2018 - 0.4.8-1
- initial spec
